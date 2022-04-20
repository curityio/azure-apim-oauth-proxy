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
command line interfaces, subscriptions...

### Create OAuth Proxy
ARM template, commands, configuration...

## Configuration
| Name | Display Name | Type | Description |
|------|--------------|------|-------------|
| `oauth-proxy-cookie-name-prefix` | OAuthProxy-CookieNamePrefix | Plain/String | The prefix of the cookies that hold the encrypted access and csrf tokens that are handled by the policy. |
| `oauth-proxy-encryption-key` | OAuthProxy-EncryptionKey | Secret/String | Base64 encoded encryption key. This key is the master key for decrypting and verifying the integrity of the cookies. |
| `oauth-proxy-trusted-origins` | OAuthProxy-TrustedOrigins | Plain/String | A whitelist of at least one web origin from which the plugin will accept requests. Multiple origins are separated by a comma and could be used in special cases where cookies are shared across subdomains. |
| `oauth-proxy-allow-tokens` | OAuthProxy-AllowTokens | Plain/Boolean | If set to true, then requests that already have a bearer token are passed straight through to APIs. This can be useful when web and mobile clients share the same API routes. |
| `oauth-proxy-use-phantom-token` | OAuthProxy-UsePhantomToken | Plain/Boolean | Set to true, if the Phantom Token pattern is used and the API Gateway should exchange opaque tokens for JWTs. |
| `oauth-proxy-introspection-url` | OAuthProxy-IntrospectionUrl | Plain/String | The URL of the introspection endpoint at the Identity Server that the API Gateway will call as part of the Phantom Token pattern to retrieve a JWT.
| `oauth-proxy-client-id` | OAuthProxy-ClientId | Plain/String | The client id used by the API Gateway when exchanging an opaque token for a JWT; part of the basic credentials required at the introspection endpoint. |
| `oauth-proxy-client-secret` | OAuthProxy-ClientSecret | Secret/String | The secret used by the API Gateway when exchanging an opaque token for a JWT; part of the basic credentials required at the introspection endpoint. |

TODO: encryption key in HEX; encryption key in KeyVault?
TODO: CORS headers; add during deployment?
TODO: during deployment: set default values
TODO: during deployment: client-id, client-secret, introspection-url should only be required if phantom-token=true
