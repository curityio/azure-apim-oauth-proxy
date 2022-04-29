# OAuth Proxy for API Gateway in Azure


[![Quality](https://img.shields.io/badge/quality-demo-red)](https://curity.io/resources/code-examples/status/)
[![Availability](https://img.shields.io/badge/availability-source-blue)](https://curity.io/resources/code-examples/status/)

This repository provides an implementation of the OAuth Proxy module of the [Token Handler Pattern](https://curity.io/resources/learn/the-token-handler-pattern/) in an API Gateway in Azure. The OAuth Proxy is implemented by a global [policy](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-policies) as part of the API Management Service. Policies allow custom actions on every API call.

## The Token Handler pattern
The Token Handler pattern consists of two components:

* the OAuth Agent, that issues secure cookies and handles the communication with the Authorization Server.
* the OAuth Proxy, that extracts access tokens from the encrypted cookies and passes the tokens to the downstream API.

## OAuth Proxy Policy
The OAuth Proxy translates tokens from encrypted cookies in inbound requests, so that APIs receive JWTs in the standard way.
The policy implements the following flow:

* Verify Origin header
* If enabled, simply forward access tokens found in the Authorization header.
* Check CSRF token and cookie for data-changing methods
* Check for valid access token cookie in all cases
* Decrypt the access token from the cookie
* If Phantom Token pattern is implemented, retrieve the JWT for the opaque token.
* Overwrite the Authorization header with the token and forward requests to the backend services (APIs).

> **NOTE**: Due to the limited set of supported classes and methods from the .NET framework in policies, the encryption algorithm used in this example is **AES256-CBC with HMAC-SHA256**. Make sure to use this implementation together with an OAuth Agent that protects the cookies with AES256-CBC and HMAC-SHA256. Other examples of the Token Handler pattern may use AES256-CBG which provides built-in message integrity.

This repository includes an ARM template with the policy and parameter file for quickly setting up an API Management Service as an OAuth Proxy. The template creates an APIM instance with a set of named values and a global policy attached that handles all the functions of an OAuth Proxy. Modify the template parameters to adapt the deployment or change the named values afterwards.

## Development
Install [Visual Studio Code](https://code.visualstudio.com/) and the extension [Azure Resource Manager (ARM) Tools](https://marketplace.visualstudio.com/items?itemName=msazurermtools.azurerm-vscode-tools&ssr=false). Open the folder `outh-proxy-template` in Visual Studio Code and start editing `oauthproxydeploy.json` or `oauthproxydeploy.parameters.json`. Refer to [Microsoft's documentation for ARM templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/).

## Create the Encryption Key
This implementation uses AES256-CBC with HMAC-SHA256. This is due to the [limited set of .Net framework types](https://docs.microsoft.com/en-us/azure/api-management/api-management-policy-expressions#CLRTypes) available in the policy expression language. Both, the encryption with AES256 and the message integrity algorithm require a key. The provided encryption key is split into half to derive two dedicated keys. Consequently, the provided key must be long enough (>=64 bytes) to serve as a master key for both algorithms.

You can use the following command to create an encryption key:

```bash
openssl rand 64 | base64
```

Note, that this key is normally shared by the OAuth Agent that generates the encrypted cookies.

## Deploying

### Prerequisites
First, sign up and get a valid subscription for [Azure](https://azure.microsoft.com/en-us/free). Then [install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli). For example, on macOS install the cli with `homebrew`:

```
brew update && brew install azure-cli
```

Once installed, log in with your account with the following command:

```
az login
```

### Create Resources
The provided template describes an instance of the Azure API Management Service with a global API policy that implements the OAuth Proxy. For demonstration, the policy shows how to combine the OAuth Proxy with the Phantom Token pattern.

Use the Azure cli to deploy the template. Specify the name of the resource group that the APIM service should be created in. Provide the parameters for configuring the OAuth Proxy. If the resource group already contains resources, make sure to run the deployment in incremental mode to add the service.

```
az deployment group create --resource-group <name-of-resource-group> --template-file oauth-proxy-template/oauthproxydeploy.json --parameters @oauth-proxy-template/oauthproxydeploy.parameters.json --mode incremental
```

Use a parameter file or specify the parameters directly in the command:

```
az deployment group create --resource-group <name-of-resource-group> --template-file oauth-proxy-template/oauthproxydeploy.json --parameters apiManagementServiceName='oauthProxyApim' publisherEmail='developer@example.com' publisherName='Dave Loper' allowTokens=true encryptionKey='JZukBT6SGAH4ti+ylhw8GJZpiP7k8i+E8WlAanA0q0A=' cookieNamePrefix='oauth-proxy' trustedOrigins= '("http://app.demo.org", "http://app.demo.org:80")' usePhantomToken=true introspectionUrl='https://idsvr.example.com' clientId='test-client' clientSecret='Secr3t!'
```

The template contains inner templates for the policy. Copy, reuse and adapt those templates in other deployments, for example to add the policy to an existing APIM instance.

## Configuration

| Name | Type | Description |
|------|------|-------------|
| `apiManagementServiceName` | String | The name of the API Management Service instance that will be created by the template. |
| `publisherEmail` | String | The email of the owner of the API Management Service. Azure sends for example a notification email to this address when the deployment is complete. |
| `publisherName` | String | The name of the owner of the API Management service.  |
| `allowTokens` | Boolean | If set to true, then requests that already have a bearer token are passed straight through to APIs. This can be useful when web and mobile clients share the same API routes. |
| `trustedOrigins` | Array | A whitelist of at least one web origin from which the OAuth Proxy will accept requests. Multiple origins are separated by a comma and could be used in special cases where cookies are shared across subdomains. Use `[]` for an empty list.|
| `cookieNamePrefix` | Plain/String | The prefix of the cookies that hold the encrypted access and csrf tokens that are handled by the policy. |
| `encryptionKey` | Secret String | Base64 encoded encryption key. This key is the master key for decrypting and verifying the integrity of the cookies. |
| `usePhantomToken` | Boolean | Set to true, if the Phantom Token pattern is used and the API Gateway should exchange opaque tokens for JWTs. |
| `introspectionUrl` | String | The URL of the introspection endpoint at the Identity Server that the API Gateway will call as part of the Phantom Token pattern to retrieve a JWT.
| `clientId` | String | The client id used by the API Gateway when exchanging an opaque token for a JWT; part of the basic credentials required at the introspection endpoint. |
| `clientSecret` | Secret String | The secret used by the API Gateway when exchanging an opaque token for a JWT; part of the basic credentials required at the introspection endpoint. |

### Example Parameters
```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "apiManagementServiceName": {
            "value": "oauthProxyApim"
        },
        "publisherEmail": {
            "value": "developer@example.com"
        },
        "publisherName": {
            "value": "Dave Loper"
        },
        "allowTokens": {
            "value": true
        },
        "trustedOrigins": {
            "value": [ "http://app.demo.org", "http://app.demo.org:80"]
        },
        "cookieNamePrefix": {
            "value": "oauth-proxy"
        },
        "encryptionKey": {
            "value": "JZukBT6SGAH4ti+ylhw8GJZpiP7k8i+E8WlAanA0q0A="
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

## Policy

For readability, the policy was added to this repository in its XML format. It uses placeholders, such as `{{OAuthProxy-AllowTokens}}` to access a named value of the API Management Service. Most of the parameters of the template result in a named value that can be accessed within the policy.

This is for example useful when adding support for CORS:

```xml
<inbound>
  <cors allow-credentials="true">
      <allowed-origins>
          <origin>https://app.demo.org</origin>
          <origin>https://app.demo.org:80</origin>
      </allowed-origins>
      <allowed-methods>
          <method>OPTIONS</method>
          <method>GET</method>
          <method>HEAD</method>
          <method>POST</method>
          <method>PUT</method>
          <method>PATCH</method>
          <method>DELETE</method>
      </allowed-methods>
      <allowed-headers>
      <!-- allow CSRF header that contains the cookie name prefix -->
          <header>x-{{OAuthProxy-CookieNamePrefix}}-csrf</header>
      </allowed-headers>
  </cors>
  ...
</inbound>
```
