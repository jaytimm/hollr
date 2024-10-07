[![](https://www.r-pkg.org/badges/version/hollr)](https://cran.r-project.org/package=hollr)
[![](http://cranlogs.r-pkg.org/badges/last-month/hollr)](https://cran.r-project.org/package=hollr)

# hollr

An R package for chat completion and text annotation with both local
LLMs and OpenAI models, emphasizing simplicity and flexibility.. Key
features include:

-   **Versatile Model Access**: Interact with either local LLMs (via
    Python/reticulate) or OpenAI models through a straightforward
    function.

-   **Multiple Annotator Support**: Facilitate text annotation workflows
    with support for multiple annotators, including ensembling and
    majority voting methods.

-   **Batch and Parallel Processing**: Handle multiple inputs
    simultaneously, leveraging local LLMs or speeding up tasks by
    utilizing multiple cores when working with OpenAI models.

-   **Consistent Output**: Ensure uniform data frame outputs across
    model types.

Ideal for users looking for a simple, unified solution for text
annotation using both local and OpenAI language models.

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

| pmid     | year | articletitle                                                                                            | ab                                                                                                                                                               |
|:---|:--|:-------------------------|:---------------------------------------|
| 39340096 | 2024 | Messaging to Reduce Booster Hesitancy among the Fully Vaccinated.                                       | Vaccine hesitancy was a serious problem in the United States throughout the COVID-19 pandemic, due in part to the reduction …                                    |
| 39320049 | 2024 | Rural reticence to inform physicians of cannabis use.                                                   | Over 75% of Americans have legal access to medical cannabis, though physical access is not uniform and can be difficult …                                        |
| 39222956 | 2024 | The prototypical UK blood donor, homophily and blood donation: Blood donors are like you, not me.       | Homophily represents the extent to which people feel others are like them and encourages the uptake of activities they feel …                                    |
| 39194099 | 2024 | The impact of conspiracy theories and vaccine knowledge on vaccination intention: a longitudinal study. | In this study, we analyzed associations between vaccination knowledge, vaccination intention, political ideology, and belief in conspiracy theories before and … |
| 39148747 | 2024 | Formative reasons for state-to-state influences on firearm acquisition in the U.S.                      | Firearm-related crimes and self-inflicted harms pose a significant threat to the safety and well-being of Americans. Investigation of firearm prevalence …       |
| 39105482 | 2024 | Role of national regime ideology for predicting biodiversity outcomes.                                  | The rapid decline of global biodiversity has engendered renewed debate about the social, economic, and political factors contributing to it. …                   |

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
    ## "country": "Country or countries where the study
    ## was conducted.",
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
  id = pmids$pmid[1:6],
  user_message = prompt[1:6], 
  cores = 1, 
  annotators = 1, 
  max_attempts = 7,
  force_json = T,
  flatten_json = T
  )
```

#### Ouput

| id       | country                        | summary                                                                                                                                                                                                                             |
|:---|:--------|:----------------------------------------------------------|
| 39340096 | United States                  | Study results demonstrate that providing scientific explanations about mRNA booster safety and effectiveness significantly improved willingness to receive the booster and enhanced trust in scientists among participants.         |
| 39320049 | United States                  | Study results demonstrate that rural Americans are less likely to disclose marijuana use to healthcare providers due to stigma, impacting their health outcomes compared to urban residents.                                        |
| 39222956 | United Kingdom                 | Study results demonstrate that ethnic minorities perceive blood donation as a White activity, influencing lower donation rates, while current donors and MSM show greater alignment with donor prototypes.                          |
| 39194099 | Brazil                         | Study results demonstrate that higher belief in vaccine conspiracy theories correlates with lower vaccination intention and knowledge, highlighting the urgent need for enhanced health education in public health strategies.      |
| 39148747 | United States                  | Study results demonstrate that state policies reducing gun homicides impact firearm acquisition patterns across states, highlighting significant relationships between laws, crime rates, and mutual influences among U.S. states.  |
| 39105482 | Not specified in the abstract. | Study results demonstrate that national political ideologies significantly influence biodiversity outcomes, with nationalism and socialism linked to threatened species, while democracy correlates with increased protected areas. |

### Parallel processing & multiple annotators

``` r
class_task2 <- hollr::hollr(
  model = 'gpt-4o-mini',
  id = pmids$pmid[1:10],
  user_message = prompt[1:10], 
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

### Batch processing

``` r
batch_seq <- hollr::hollr(
  model = llm,
  id = pmids$pmid[1:10],
  user_message = prompt[1:10], 
  
  annotators = 3, 
  #max_attempts = 7,
  force_json = F,
  flatten_json = F,
  max_new_tokens = 75, 
  batch_size = 5
  )
```
