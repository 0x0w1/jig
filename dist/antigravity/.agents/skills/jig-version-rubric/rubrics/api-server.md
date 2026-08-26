# API Server Version Policy

> Basis: SemVer API server, adopted `<date>`

## Public Interface

- Endpoint methods and paths
- Request, response, and error schemas and their meaning
- HTTP status codes, headers, pagination, default ordering
- Authentication and authorization schemes and scopes
- Webhook, event, and rate-limit contracts
- Published API generations and how long they are supported

Internal storage, frameworks, and deployment topology are not the public interface unless they affect the external contract.

Whether adding a response field is a compatible change depends on whether the contract with clients says unknown fields are ignored. Without that contract the whole response schema is public, and adding a field is `major`.

## Decision Order

1. Did it fix wrong behavior, performance, or stability while keeping the public API contract? → `patch`
2. Did it only add optional endpoints, fields, or features while keeping existing requests and responses? → `minor`
3. Must existing callers change how they request, parse, authenticate, or handle errors? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | A fix that keeps the API contract and its meaning | status code corrected to match the spec, N+1 removed, timeout stabilized |
| `minor` | API growth that leaves existing calls untouched | new endpoint, optional request field, additive response field |
| `major` | A change incompatible with existing calls, parsing, or auth | endpoint removed, required field added, field meaning changed, auth scheme replaced |

## Hard Rules

> A change where the existing request still succeeds but the meaning, permissions, or side effects of the result differ is `major`.

## Pre-Release Checks

- Check for breaking changes with an OpenAPI or schema diff.
- Run contract tests against the client versions still supported.
- Check how data migration and rollback affect existing API responses.

## Version Format

- The product's SemVer and an API generation marker such as `/v1` in the URL are separate. A product release can be `major` while the API generation holds, and a new API generation can be added alongside in a `minor` release.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
