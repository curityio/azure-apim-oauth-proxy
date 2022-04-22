# OAuth Proxy for API Gateway in Azure
This repository provides an implementation of the OAuth Proxy module of the [Token Handler Pattern](https://curity.io/resources/learn/the-token-handler-pattern/) in an API Gateway in Azure. The OAuth Proxy is implemented by a global [policy](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-policies) as part of the API Management Service. Policies allow custom actions on every API call.

## The Token Handler pattern
The Token Handler pattern consists of two components:

* the OAuth Agent, that issues secure cookies and handles the communication with the Authorization Server.
* the OAuth Proxy, that extracts access tokens from the encrypted cookies and passes the tokens to the downstream API.

## OAuth Proxy Policy
The OAuth Proxy translates tokens from encrypted cookies in inbound requests, so that APIs receive JWTs in the standard way.
The policy implements the following flow:

* Check and set CORS headers
* Verify Origin header
* Check CSRF token and cookie for data-changing data-changing methods
* If enabled, simply forward access tokens found in the Authorization header.
* Check for valid access token cookie in all other cases
* Encrypt the access token from the cookie
* If Phantom Token pattern is implemented, retrieve the JWT for the opaque token.
* Overwrite the Authorization header with the token and forward requests to the backend services (APIs).

> **NOTE**: Due to the limited set of supported classes and methods from the .NET framework in policies, the encryption algorithm used in this example is **AES256-CBC with HMAC-SHA256**. Make sure to use this implementation together with an OAuth Agent that protects the cookies with AES256-CBC and HMAC-SHA256. Other examples of the Token Handler pattern may use AES256-CBG which provides built-in message integrity.

## Deploying

### Prerequisites
```bash
az deployment group create --resource-group <name-of-resource-group> --template-file arm-template/oauth-proxy-template.json --name <name-of-the-apim-service> --parameters @arm-template/example-parameters.json --mode incremental
```

command line interfaces, subscriptions...

### Create OAuth Proxy
ARM template, commands, configuration...

## Configuration
| Name | Type | Description |
|------|--------------|------|-------------|
| `cookieNamePrefix` |  Plain/String | The prefix of the cookies that hold the encrypted access and csrf tokens that are handled by the policy. |
| `encryptionKey` | Secret/String | Base64 encoded encryption key. This key is the master key for decrypting and verifying the integrity of the cookies. |
| `trustedOrigins` | Plain/String | A whitelist of at least one web origin from which the OAuth Proxy will accept requests. Multiple origins are separated by a comma and could be used in special cases where cookies are shared across subdomains. |
| `allowTokens` | Plain/Boolean | If set to true, then requests that already have a bearer token are passed straight through to APIs. This can be useful when web and mobile clients share the same API routes. |
| `usePhantomToken` | Plain/Boolean | Set to true, if the Phantom Token pattern is used and the API Gateway should exchange opaque tokens for JWTs. |
| `introspectionUrl` | Plain/String | The URL of the introspection endpoint at the Identity Server that the API Gateway will call as part of the Phantom Token pattern to retrieve a JWT.
| `clientId` | Plain/String | The client id used by the API Gateway when exchanging an opaque token for a JWT; part of the basic credentials required at the introspection endpoint. |
| `clientSecret` | Secret/String | The secret used by the API Gateway when exchanging an opaque token for a JWT; part of the basic credentials required at the introspection endpoint. |

## Create encryption key


### Example Parameters
```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "apiManagementServiceName": {
            "value": "test-apim"
        },
        "publisherEmail": {
            "value": "developer@example.org"
        },
        "publisherName": {
            "value": "Dave Loper"
        },
        "allowTokens": {
            "value": true
        },
        "encryptionKey": {
            "value": "JZukBT6SGAH4ti+ylhw8GJZpiP7k8i+E8WlAanA0q0A="
        },
        "cookieNamePrefix": {
            "value": "oauth-proxy"
        },
        "trustedOrigins": {
            "value": [ "http://app.demo.org", "http://app.demo.org:80"]
        },
        "usePhantomToken": {
            "value": true
        },
        "introspectionUrl": {
          "value": "https://idsvr.example.com"
        },
        "clientId": {
          "value": "test-client"
        },
        "clientSecret": {
          "value": "Secr3t!"
        }
    }
}
```
TODO: encryption key in HEX; encryption key in KeyVault?
TODO: CORS headers; add during deployment?
