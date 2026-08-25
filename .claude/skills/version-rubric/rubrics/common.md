# Common SemVer Principles

`major`, `minor`, and `patch` mean the same thing in every project type. What changes from type to type is what counts as the public interface.

## What Is Graded

Look at what someone using the version just before this release has to change to move to the new one. A consumer is not only an end user: it can be an API caller, another package, an automation script, stored data, a plugin, or an operator.

None of the following is grounds for a grade:

- Whether a human or an AI wrote it
- How much code, documentation, or how many files changed
- How hard it was or how long it took
- The number of commits and contributors
- A model or framework generation turning over, by itself

A generation change that keeps the public contract is `patch`, one that adds backward-compatible capability is `minor`, and one that breaks existing consumers is `major`.

## Common Decision Order

1. Did it fix wrong behavior while keeping the public interface? → `patch`
2. Can existing consumers keep going untouched, with only new capability added? → `minor`
3. Must existing consumers change code, configuration, data, or the way they work? → `major`

Stop at the first grade that matches. When several public interfaces are affected, grade each one separately and use the highest grade.

## Judging Compatibility

### `patch`

- Only documentation, tests, or internal structure changed; public behavior is identical
- Behavior that contradicted the spec was fixed in a compatible way
- Performance or stability improved while the input, output, and side-effect contract held
- A dependency was raised without changing what consumers support or how they call it

Restoring the documented contract is a `patch` even when someone depended on the bug. It becomes `major` when that behavior had long been the de facto public contract, or when existing data or automation breaks after the fix.

### `minor`

- Optional features, new APIs, or new commands were added and coexist with the existing usage
- The accepted range widened while existing inputs and results stayed the same
- A new platform or runtime is supported
- A deprecation notice was added while the existing behavior kept working

If a new feature changes an existing default or the result of an existing call, it is not a backward-compatible addition and does not grade as `minor`.

### `major`

- A public name, signature, schema, file format, or URL was removed or changed
- New required configuration or required input is demanded
- Existing input still succeeds but its meaning or result quietly differs
- A supported platform, runtime, or protocol was dropped
- Manual data conversion or consumer code changes are required

Clear errors and a migration guide do not change the fact that the change is incompatible. Good guidance makes the release safer; it does not lower the SemVer grade.

## AI Behavior and Prompts

An AI model, a prompt, or an agent instruction can be an implementation detail or a public interface.

- Internal prompt work that keeps the allowed range of results and the guarantees for the same input → `patch`
- New opt-in capability added while existing guarantees hold → `minor`
- The default response policy, the conditions for running a tool, a safety boundary, or the output schema changed incompatibly for existing consumers → `major`

Do not raise every change to `major` merely because the system is non-deterministic. Grade against the documented guarantees and the allowed range.

## Before 1.0 and Prereleases

Under SemVer, `0.y.z` signals that the public interface may not be stable. Even so, grade and record the change as `patch`, `minor`, or `major` first. Under the SPAI default format, a `major` grade in `0.x` is expressed as `v0.(Y+1).0`.

Prerelease markers such as `alpha`, `beta`, and `rc` are stability stages, not substitutes for a compatibility grade. Settle the base version first, then attach the prerelease identifier.

## Composite Projects

When one release ships a server, a client, and an SDK together, follow this order.

1. Grade each artifact's public interface independently.
2. If they version together as one product, apply the highest grade to the product version.
3. If they version independently, raise only the affected artifacts.
4. If the compatible range between artifacts changes, grade that range itself as a public interface.
