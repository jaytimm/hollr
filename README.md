# hollr

An R package that provides a simple interface for text completion via
either the OpenAI API or local language models – with a focus on text
annotation, text-to-json, etc.

## Features

**Versatile Model Integration**: Seamlessly generate text using OpenAI
models like GPT-3.5 and GPT-4, or local models, via a single function.

**Multiple Annotators**: Support for multiple annotators to handle
ensembling methods and majority voting, improving the reliability and
accuracy of text completions.

**Parallel Processing**: Leverage multiple cores for faster processing
with cloud-based models.

**Consistent Output**: Provides a consistent data frame output across
different models.

**Prompt Diagnostics**: Includes basic prompt diagnostics to help
understand and improve the input prompts.

**Robust JSON Handling**: Ensures consistent and valid JSON output, with
multiple attempts to generate correct responses.
