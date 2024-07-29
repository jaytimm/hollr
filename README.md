# hollr

An R package that provides a single, simple interface for text
completion via the OpenAI API and local LLMs – with a focus on text
annotation, text-to-json, and consistent data frame output.

## Features

**Versatile Model Integration**: Seamlessly access OpenAI models like
gpt-4o and gpt-4o-mini, or local models, via a single function.

**Multiple Annotators**: Support for multiple annotators to handle
ensembling methods and majority voting, improving the reliability and
accuracy of text completions.

**Parallel Processing**: Leverage multiple cores for faster processing
with cloud-based models.

**Consistent Output**: Provides a consistent data frame output across
different models.

**Prompt Diagnostics**: Includes basic prompt diagnostics to help
understand and improve the input prompts.

**Robust JSON Handling**: Ensures consistent and valid JSON output.
