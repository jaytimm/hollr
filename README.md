# hollr

An R package providing a unified interface for text completion via local
and cloud-based LLMs, tailored for text annotation tasks.

#### Features

-   **Versatile Model Integration**: Facilitates seamless access to both
    cloud-based and local LLMs via a single function.

-   **Multiple Annotators**: Supports multiple annotators to handle
    ensembling methods and majority voting.

-   **Batch Processing for Local LLMs**: Enables batch processing to
    handle multiple inputs simultaneously.

-   **Parallel Processing**: Leverages multiple cores for faster
    processing with cloud-based models.

-   **Consistent Output**: Provides a consistent data frame output
    across different models.

-   **Prompt Diagnostics**: Includes basic prompt diagnostics to help
    understand and improve input prompts.

-   **Robust JSON Handling**: Ensures consistent and valid JSON output.

------------------------------------------------------------------------

## Conda environment & reticulate

``` bash
# Create and activate a new conda environment with Python 3.9
conda create -n llm_base python=3.9 -y
conda activate llm_base

# Update all packages in the environment
conda update --all -y

# Install required packages with conda
conda install nmslib pandas numpy spacy -c conda-forge -y
conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia -y

# Install additional packages with pip
pip install transformers packaging ninja flash-attn --no-build-isolation accelerate protobuf auto-gptq \
"git+https://github.com/PanQiWei/AutoGPTQ.git@v0.6.0" optimum tiktoken sentencepiece
```

``` r
# Set environment variables and use conda environment
Sys.setenv(RETICULATE_PYTHON = file.path(miniconda_path, "envs", env_name, "bin/python"))
reticulate::use_condaenv(condaenv = env_name, conda = file.path(miniconda_path, "bin/conda"))
```

## Some prompts and data

### Sample prompts

> `hollr` includes some sample prompts and text data.

``` r
hollr::pretty_prompt(hollr::prompts$FeaturizeTextYN)
```

    ## Role
    ## As a political researcher for a think tank, your
    ## task is to analyze and categorize abstracts
    ## related to political ideology in America. You
    ## will answer five yes/no questions for each
    ## abstract to identify key themes and
    ## methodological aspects. This structured
    ## representation will help the think tank
    ## understand trends and insights in political
    ## behavior, guiding policy recommendations.
    ## 
    ## Task
    ## Features to Identify:
    ## 
    ## pol_ideo: Does the abstract mention political
    ## ideology or its influence on behaviors or
    ## beliefs?
    ## survey_long: Is the research based on survey data
    ## collection or involves longitudinal data
    ## (multiple waves of data collection)?
    ## demo_geo: Does the abstract include an analysis
    ## of demographic factors (e.g., age, gender,
    ## education) or mention geographic/regional
    ## differences within the United States?
    ## health_policy: Is the study related to public
    ## health issues, or does it address implications
    ## for policymakers or public health interventions?
    ## misinfo_media_trust: Does the abstract discuss
    ## misinformation, media impact, or trust in
    ## government/public institutions?
    ## 
    ## 
    ## 
    ## Example Input:
    ## 
    ## "Personal similarities to a transgressor makes
    ## one view the transgression as less immoral. We
    ## investigated whether personal relevance might
    ## also affect the perceived immorality of
    ## politically-charged threats. We hypothesized that
    ## increasing the personal relevance of a threat
    ## would lead participants to report the threat as
    ## more immoral, even for threats the participant
    ## might otherwise view indifferently. U.S.
    ## participants recruited online (N = 488) were
    ## randomly assigned to write about the personal
    ## relevance of either a liberal threat (pollution),
    ## conservative threat (disrespecting an elder),
    ## neutral threat (romantic infidelity), or given a
    ## control filler task. Participants then rated how
    ## immoral and personally relevant each political
    ## threat was, as well as reported their political
    ## ideology. Partial support for our hypothesis
    ## emerged: when primed with conservative writing
    ## prompts, liberal-leaning participants rated the
    ## conservative threat as more immoral, compared
    ## with the same threat after a liberal writing
    ## prompt. We did not find these results for
    ## conservative-leaning participants, perhaps
    ## because all participants cared relatively equally
    ## about the liberal threat."
    ## 
    ## 
    ## 
    ## Expected Output:
    ## 
    ## {
    ## "pol_ideo": true,
    ## "survey_long": true,
    ## "demo_geo": false,
    ## "health_policy": false,
    ## "misinfo_media_trust": false
    ## }

### Sample data

``` r
# Use the function to truncate the abstract column
pic <- hollr::political_ideology
pic$ab <- truncate_abstract_vector(pic$abstract, 20)
pic |> dplyr::select(pmid, year, articletitle, ab) |> 
  head(3) |> knitr::kable()
```

| pmid     | year | articletitle                                                                                 | ab                                                                                                                                                    |
|:---|:--|:-------------------------|:----------------------------------------|
| 30247057 | 2018 | Prior exposure increases perceived accuracy of fake news.                                    | The 2016 U.S. presidential election brought considerable attention to the phenomenon of “fake news”: entirely fabricated and often partisan content … |
| 37947551 | 2023 | Public Health Policy, Political Ideology, and Public Emotion Related to COVID-19 in the U.S. | Social networks, particularly Twitter 9.0 (known as X as of 23 July 2023), have provided an avenue for prompt interactions …                          |
| 28895229 | 2017 | Crisis and Change: The Making of a French FDA.                                               | Policy Points: Introducing a recent special issue of The Lancet on the health system in France, Horton and Ceschia observe …                          |

``` r
class_task_prompt <- paste(paste(hollr::prompts$FeaturizeTextYN, 
                                 'Abstract:', sep = '\n\n'),
                           hollr::political_ideology$abstract, sep = '\n')
```

## Cloud-based LLMs

### Force JSON

``` r
class_task1 <- hollr::hollr(
  model = 'gpt-4o-mini',
  id = hollr::political_ideology$pmid[1:10],
  user_message = class_task_prompt[1:10], 
  cores = 1, 
  annotators = 1, 
  max_attempts = 7,
  force_json = T,
  flatten_json = T
  )

class_task1 |> knitr::kable()
```

| id       | annotator_id | attempts | success | pol_ideo | survey_long | demo_geo | health_policy | misinfo_media_trust |
|:------|:--------|------:|:-----|:------|:--------|:------|:---------|:-------------|
| 30247057 | jt8h0KxV4n   |        1 | TRUE    | TRUE     | TRUE        | FALSE    | FALSE         | TRUE                |
| 37947551 | jt8h0KxV4n   |        1 | TRUE    | TRUE     | FALSE       | TRUE     | TRUE          | FALSE               |
| 28895229 | jt8h0KxV4n   |        1 | TRUE    | TRUE     | FALSE       | FALSE    | TRUE          | FALSE               |
| 34341651 | jt8h0KxV4n   |        1 | TRUE    | TRUE     | TRUE        | TRUE     | TRUE          | FALSE               |
| 25316309 | jt8h0KxV4n   |        1 | TRUE    | FALSE    | FALSE       | FALSE    | TRUE          | FALSE               |
| 22904584 | jt8h0KxV4n   |        1 | TRUE    | TRUE     | TRUE        | FALSE    | FALSE         | FALSE               |
| 7183563  | jt8h0KxV4n   |        1 | TRUE    | TRUE     | TRUE        | FALSE    | TRUE          | FALSE               |
| 33199928 | jt8h0KxV4n   |        1 | TRUE    | TRUE     | TRUE        | TRUE     | TRUE          | FALSE               |
| 35270435 | jt8h0KxV4n   |        1 | TRUE    | TRUE     | TRUE        | TRUE     | FALSE         | FALSE               |
| 35250760 | jt8h0KxV4n   |        1 | TRUE    | TRUE     | TRUE        | TRUE     | FALSE         | FALSE               |

### Parallel processing

``` r
class_task2 <- hollr::hollr(
  model = 'gpt-4o-mini',
  id = hollr::political_ideology$pmid[1:10],
  user_message = class_task_prompt[1:10], 
  cores = 7, 
  annotators = 3, 
  max_attempts = 7,
  force_json = T,
  flatten_json = T
  )
```

## Local LLMs

``` r
llm = 'meta-llama/Meta-Llama-3.1-8B-Instruct'
```

### Sequential

``` r
local_seq <- hollr::hollr(
  model = 'meta-llama/Meta-Llama-3.1-8B-Instruct',
  id = hollr::political_ideology$pmid[1:10],
  user_message = class_task_prompt[1:10], 
  # cores = 7, 
  annotators = 3, 
  #max_attempts = 7,
  force_json = F,
  flatten_json = F,
  max_new_tokens = 75, 
  batch_size = 1
  )
```

### Batch processing

``` r
batch_seq <- hollr::hollr(
  model = 'meta-llama/Meta-Llama-3.1-8B-Instruct',
  id = hollr::political_ideology$pmid[1:10],
  user_message = class_task_prompt[1:10], 
  # cores = 7, 
  annotators = 3, 
  #max_attempts = 7,
  force_json = F,
  flatten_json = F,
  max_new_tokens = 75, 
  batch_size = 5
  )
```
