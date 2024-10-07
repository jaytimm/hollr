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
  id = pmids$pmid[1:10],
  user_message = prompt[1:10], 
  cores = 1, 
  annotators = 1, 
  max_attempts = 7,
  force_json = T,
  flatten_json = T
  )
```

| id       | country                                   | summary                                                                                                                                                                                                                                                          |
|:--|:----------|:---------------------------------------------------------|
| 39340096 | United States                             | Study results demonstrate that providing scientific explanations about mRNA booster safety and effectiveness significantly increased willingness to get boosted and improved trust in scientists among participants.                                             |
| 39320049 | United States                             | Study results demonstrate that rural Americans are less likely to disclose marijuana use to healthcare providers due to stigma, impacting their health outcomes and effective medical care.                                                                      |
| 39222956 | United Kingdom                            | Study results demonstrate that perceptions of the prototypical UK blood donor influence donation behavior, with ethnic minorities showing the lowest homophily and higher homophily linked to greater donation commitment.                                       |
| 39194099 | Brazil                                    | Study results demonstrate that stronger belief in vaccine conspiracy theories correlates with lower vaccination intention and knowledge, while political ideology and demographics influence these beliefs over time.                                            |
| 39148747 | United States                             | Study results demonstrate that firearm acquisition patterns across U.S. states are influenced by gun homicide rates, firearm law strictness, and geographic and ideological factors, impacting regional policy effectiveness.                                    |
| 39105482 | Not specified                             | Study results demonstrate that political ideologies like nationalism and socialism negatively influence threatened animal species, while democracy positively affects protected area establishment, indicating the importance of tailored conservation policies. |
| 39102194 | High- and low-income countries worldwide. | Study results demonstrate that COVID-19 politicization influenced public health compliance, with conservatives showing increased vaccine hesitancy and poorer health outcomes compared to their left-wing counterparts.                                          |
| 39101909 | United States                             | Study results demonstrate that pro-diversity messages in job recruitment can unintentionally foster hiring biases based on political ideology, affecting both conservative and liberal hiring recommendations for minorities.                                    |
| 39101906 | United States                             | Study results demonstrate notable differences in collective memory between Black and White Americans, with Black participants emphasizing race-relevant events, and memories showing temporary malleability after George Floyd’s murder.                         |
| 39093836 | Poland                                    | Study results demonstrate that political ideology significantly influences public acceptance of energy sources in Poland, alongside environmental attitudes, risk perception, and economic factors affecting energy policy support.                              |

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

### Sequential processing

``` r
local_seq <- hollr::hollr(
  model = llm,
  id = pmids$pmid[1:10],
  user_message = prompt[1:10], 
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
