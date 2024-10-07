[![](https://www.r-pkg.org/badges/version/hollr)](https://cran.r-project.org/package=hollr)
[![](http://cranlogs.r-pkg.org/badges/last-month/hollr)](https://cran.r-project.org/package=hollr)

# hollr

An R package designed for efficient chat completion and text annotation
using both local and cloud-based LLMs, with a focus on simplicity and
flexibility. Key features include:

**Versatile Model Access**: Interact with cloud-based or local LLMs (via
Python/reticulate) through a straightforward function.

**Multiple Annotator Support**: Facilitate text annotation workflows
with support for multiple annotators, including ensembling and majority
voting methods.

**Batch and Parallel Processing**: Handle multiple inputs simultaneously
with local LLMs and speed up tasks by utilizing multiple cores for
cloud-based models.

**Consistent Output**: Ensure uniform data frame outputs regardless of
the model used, keeping results easily manageable.

Ideal for users looking for a simple, unified solution for text
annotation with both local and cloud-based language models.

## Installation

Get the development version from GitHub with:

``` r
remotes::install_github("jaytimm/hollr")
```

## Usage

## A quick example

### Some PubMed data

``` r
pmids <- puremoe::search_pubmed('("political ideology"[TiAb])',
                                 use_pub_years = F) |> 
  puremoe::get_records(endpoint = 'pubmed_abstracts', 
                       cores = 3, 
                       sleep = 1) 
```

``` r
pmids |> dplyr::mutate(ab = truncate_abstract_vector(abstract, 20)) |>
  dplyr::select(pmid, year, articletitle, ab) |> 
  head(3) |> knitr::kable()
```

| pmid     | year | articletitle                                                                                      | ab                                                                                                                            |
|:---|:--|:----------------------------|:------------------------------------|
| 39340096 | 2024 | Messaging to Reduce Booster Hesitancy among the Fully Vaccinated.                                 | Vaccine hesitancy was a serious problem in the United States throughout the COVID-19 pandemic, due in part to the reduction … |
| 39320049 | 2024 | Rural reticence to inform physicians of cannabis use.                                             | Over 75% of Americans have legal access to medical cannabis, though physical access is not uniform and can be difficult …     |
| 39222956 | 2024 | The prototypical UK blood donor, homophily and blood donation: Blood donors are like you, not me. | Homophily represents the extent to which people feel others are like them and encourages the uptake of activities they feel … |

### A quick prompt

    ## For the PubMed abstract provided below, provide a
    ## single sentence summary of the research findings
    ## in 30 words. Ensure that the summary is concise,
    ## starts with "Study results demonstrate," and
    ## highlights the key outcomes. Also, identify the
    ## country or countries where the study was
    ## conducted.
    ## 
    ## Expected Output:
    ## {
    ## "country_studied": "Country or countries where
    ## the study was conducted.",
    ## "summary": "Study results demonstrate ...
    ## (summary of the research findings in 30 words)."
    ## }
    ## 
    ## Abstract:

## Cloud-based LLMs

``` r
prompt <- paste(p1, pmids$abstract, sep = '\n\n')
```

### Single core & single annotator

``` r
class_task1 <- hollr::hollr(
  model = 'gpt-4o-mini',
  id = pmids$pmid[1:10],
  user_message = prompt[1:10], 
  cores = 1, 
  annotators = 1, 
  max_attempts = 7,
  force_json = T,
  flatten_json = T
  )
```

``` r
class_task1 |> knitr::kable()
```

| id       | annotator_id | attempts | success | country_studied                                                                                                                   | summary                                                                                                                                                                                                                                           |
|:--|:---|--:|:--|:---------------------|:---------------------------------------|
| 39340096 | Q0qAxTCzJl   |        1 | TRUE    | United States                                                                                                                     | Study results demonstrate that providing safety and effectiveness explanations significantly enhanced participants’ trust in vaccine technology and willingness to receive the mRNA booster, regardless of political ideology.                    |
| 39320049 | Q0qAxTCzJl   |        1 | TRUE    | United States                                                                                                                     | Study results demonstrate that rural Americans face stigma affecting their disclosure of marijuana use to healthcare providers, contrasting with urban residents who report usage more openly.                                                    |
| 39222956 | Q0qAxTCzJl   |        1 | TRUE    | United Kingdom                                                                                                                    | Study results demonstrate that current donors and MSM exhibit higher homophily to the prototypical UK blood donor, impacting ethnic minorities’ donation likelihood, highlighting recruitment strategy needs.                                     |
| 39194099 | Q0qAxTCzJl   |        1 | TRUE    | Brazil                                                                                                                            | Study results demonstrate that stronger belief in vaccine conspiracy theories correlates with lower vaccination intention and knowledge, highlighting the need for health education to counter misinformation.                                    |
| 39148747 | Q0qAxTCzJl   |        1 | TRUE    | United States                                                                                                                     | Study results demonstrate that firearm acquisition patterns in U.S. states are influenced by homicide rates, firearm laws, geography, and citizen ideology, affecting inter-state firearm acquisition dynamics.                                   |
| 39105482 | Q0qAxTCzJl   |        1 | TRUE    | The study does not specify a particular country, but it investigates national regime ideology and biodiversity outcomes globally. | Study results demonstrate that political ideologies like nationalism and socialism adversely affect threatened species, while increased democracy enhances protected area establishment, highlighting the link between politics and biodiversity. |
| 39102194 | Q0qAxTCzJl   |        1 | TRUE    | High- and low-income countries worldwide                                                                                          | Study results demonstrate that politicization of COVID-19 led to poorer health outcomes, higher infection rates, and vaccine hesitancy among conservatives compared to the left-wing populace across diverse countries.                           |
| 39101909 | Q0qAxTCzJl   |        1 | TRUE    | United States                                                                                                                     | Study results demonstrate that pro-diversity messages in recruitment can backfire, eliciting hiring biases based on race and political ideology, potentially undermining diversity initiatives’ intended outcomes.                                |
| 39101906 | Q0qAxTCzJl   |        1 | TRUE    | United States                                                                                                                     | Study results demonstrate significant differences in collective memory between Black and White Americans, with race-relevant events increasing following the murder of George Floyd, highlighting the malleability of collective memories.        |
| 39093836 | Q0qAxTCzJl   |        1 | TRUE    | Poland                                                                                                                            | Study results demonstrate public acceptance of energy sources in Poland is primarily influenced by political ideology, with environmental attitudes and economic factors also playing significant roles.                                          |

### Parallel processing & multiple annotators

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

### Conda environment

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

### Reticulate

``` r
# Set environment variables and use conda environment
Sys.setenv(RETICULATE_PYTHON = file.path(miniconda_path, "envs", env_name, "bin/python"))
reticulate::use_condaenv(condaenv = env_name, conda = file.path(miniconda_path, "bin/conda"))
```

``` r
llm = 'meta-llama/Meta-Llama-3.1-8B-Instruct'
```

### Sequential processing

``` r
local_seq <- hollr::hollr(
  model = llm,
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
  model = llm,
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
