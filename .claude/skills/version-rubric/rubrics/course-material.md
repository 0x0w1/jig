# Course Material Version Policy

> Basis: SemVer course material, adopted `<date>`

## Public Interface

- The curriculum order and the position and number of each session
- What a learner should be able to do when a session ends
- Exercise instructions, grading criteria, and how far solutions are revealed
- The environment an exercise needs: tools, versions, prerequisites, data
- The distribution form (slides, notebooks, print) and the files handed to learners
- Assumed prior knowledge and expected time

Explanatory sentences, swapped examples, and slide design are not the public interface as long as the learning objectives and exercise results hold.

## Decision Order

1. Were explanations, examples, or typos fixed while session order and exercise results held? → `patch`
2. Were existing sessions left in place while supplements, exercises, or appendices were added? → `minor`
3. Must the teacher change the plan, or the learner change environment or deliverables? → `major`

## Grade Definitions

| bump | definition | examples |
|---|---|---|
| `patch` | Material fixes that leave the delivery unchanged | explanation expanded, example swapped, typo fixed, image improved |
| `minor` | Additions that coexist with existing sessions | advanced exercise, further reading, new appendix session |
| `major` | A change to delivery, environment, or assessment | sessions reordered, exercise tool or version swapped, grading criteria changed, assignment removed |

## Hard Rules

> If a tool or version in the exercise environment changes so that following the existing instructions fails, it is `major`.

> If grading criteria or the deliverable format changes, it is `major`, because it changes the outcome for learners already partway through.

## Interface Paths

| path glob | interface | floor |
|---|---|---|
| `**/syllabus.*`, `**/outline.*`, `**/INDEX.md` | curriculum order and session numbering | `minor` |
| `**/grading.*`, `**/rubric.*` | grading criteria and the deliverable format | `minor` |
| `environment.yml`, `requirements*.txt`, `package.json`, `Dockerfile`, `.tool-versions` | the environment an exercise needs | `minor` |
| `**/exercises/**`, `**/solutions/**` | exercise wording and worked answers | `patch` |
| `slides/**`, `notebooks/**`, `sessions/**` | explanations and examples | `patch` |

## Pre-Release Checks

- Walk an exercise from the start and confirm the instructions match the result.
- Run the example code and notebooks on the tool versions the material names.
- Confirm cross-session references still hold, where one session's output feeds the next.

## Version Format

- The cohort or term and the repository version are separate. A `major` grade during a running cohort means learners in progress need to be told.
- A `major` grade in `0.x` is expressed as `v0.Y.Z` → `v0.(Y+1).0`, while the grade is still recorded as `major`.
