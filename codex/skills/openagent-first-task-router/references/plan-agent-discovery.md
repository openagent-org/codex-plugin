# Agent Discovery Query Plan

For each capability task identified by the Router, use the user's original request, explicit task context, and any trusted entity directory to produce one JSON planner request containing `query_plan`, `page`, and `size`. Plan only: do not search, select an Agent, produce a benchmark answer, or add commentary or Elasticsearch DSL to the request.

## Build the plan

- Copy the user's original wording verbatim into `raw_query` and set `query_language` to its language. Describe the current task's goal in one sentence in `goal`. In `intent_text`, state the concrete task, the object being processed, and the desired output. Drop conversational filler. Preserve applicable shared constraints when planning one task within a larger request.
- Use only what the user or trusted context supplies. Do not add translations, industry scenarios, unrelated capabilities, or inferred preferences.
- Preserve the relationship between capabilities. “Restore the image or remove its background, either is fine” is one group of alternatives. “Read it, summarize it, and send the summary” requires all three actions if the user asks one Agent to complete the sequence.
- Use `agent-query-planner-v1` and omit `discovery` when there is no explicit soft preference, when looking up an Agent by name, or when one Agent must complete a whole multi-step task. Otherwise, use `agent-query-planner-v2` for the explicit soft preference and include just one group of alternatives in `required_capabilities`.
- For each capability, write the action and object in `capability_name`, the work to be done in `capability_query_text`, and the user's purpose and desired outcome in `capability_intent_query_text`. Use English snake_case request labels for `capability_id`, `canonical_action`, and `canonical_object`. Populate `entity_ids` and `capability_entity_ids` only with IDs from the trusted directory. Ask for clarification when an entity is unknown. `confidence` reflects confidence in extraction only.
- Preserve explicitly requested platforms, permissions, deployment modes, languages, publisher verification, official status, and output types in the corresponding `filters` or `expected_output_types` fields. Record explicit prohibitions in `forbidden_effects`. Keep unsupported hard requirements and note their limitations in `planner_warnings`; never drop a requirement to pass validation or turn “do not send/publish/charge” into a positive search term.
- For v2, put only explicit preferences such as “ideally” or “prefer” in `discovery.preference_text`. Extract zero to eight concrete phrases from those preferences for `preference_keywords`. Omit Agent names, generic terms, and guessed synonyms. Keep soft preferences optional.
- Use `[]` for arrays without values and `null` for unconstrained `official` and `publisher_verified`. Omit scoring weights, search-engine parameters, expected result IDs, preferred candidates, and evaluation labels. A search match alone does not establish permission or successful execution.

## Example planner output

User: “Sharpen this blurry old photo. I would prefer a natural look.”

```json
{
  "query_plan": {
    "planner_version": "agent-query-planner-v2",
    "raw_query": "Sharpen this blurry old photo. I would prefer a natural look.",
    "query_language": "en-US",
    "goal": "Make the old photo clearer",
    "intent_text": "Sharpen the blurry old photo, preferably preserving its natural appearance.",
    "entity_ids": [],
    "required_capabilities": [{
      "capability_id": "restore_old_photo",
      "capability_name": "Restore an old photo",
      "canonical_action": "restore",
      "canonical_object": "old_photo",
      "capability_query_text": "Sharpen the blurry old photo.",
      "capability_intent_query_text": "Make the old photo clearer while preserving a natural look.",
      "capability_entity_ids": [],
      "expected_output_types": [],
      "confidence": 0.95
    }],
    "forbidden_effects": [],
    "filters": {
      "platforms": [], "permission_classes": [], "deployment_modes": [],
      "languages": [], "lifecycle_status": [],
      "publisher_verified": null, "official": null
    },
    "planner_warnings": [],
    "discovery": {
      "preference_text": "Preserve a natural look",
      "preference_keywords": ["natural look"]
    }
  },
  "page": 1,
  "size": 100
}
```

## Pass the plan to Agent Search

The planner envelope defaults to `page=1` and `size=100`. For the Router's headless MCP search, pass only its inner object as the `query_plan` argument. Omit the top-level `q` key. Use the MCP tool's pagination parameters; the planner's `size` is a page size, not a result count or an MCP argument.

Generate the plan once for the same task, original wording, and context. For another page, reuse that exact plan and page size, increment `page`, and stop paging when `has_more=false`. Do not rewrite the plan to fit returned candidates.
