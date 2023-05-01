# https://github.com/Azure/azure-cli/issues/19591
# https://iceburn.medium.com/azure-cli-docker-containers-7059750be1f2
FROM mcr.microsoft.com/dotnet/aspnet:7.0-alpine AS base
ENV DOTNET_CLI_TELEMETRY_OPTOUT=true \
    AZ_INSTALLER=DOCKER
RUN apk add --no-cache py3-pip && \
    apk add --no-cache --virtual=build gcc musl-dev python3-dev libffi-dev openssl-dev cargo make && \
    pip install --no-cache-dir azure-cli && \
    apk del --purge build
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV AZURE_CONFIG_DIR=/app/.azure

# This is the image we use to build the dotnet part of the project
# We currently need to use a preview build of .NET SDK 8 since we need to build multi platform .NET images.
# It should be backported to .NET SDK 7.0.300, but that hasn't been released at this time.
# https://devblogs.microsoft.com/dotnet/improving-multiplatform-container-support/
# https://github.com/dotnet/dotnet-docker/blob/main/samples/build-for-a-platform.md
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0-preview-alpine AS publish
ARG TARGETARCH
WORKDIR /src
COPY . .
RUN dotnet publish "AzureCliCredentialProxy.csproj" -c Release -o /app/publish -a $TARGETARCH

FROM base AS final
# RUN adduser --disabled-password --home /app --gecos '' app && chown -R app /app
# USER app
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "AzureCliCredentialProxy.dll"]