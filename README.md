# hollr

An R package offering a unified interface for text completion through
local and cloud-based LLMs, with a particular emphasis on text
annotation tasks.

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

## Some prompts and data

``` r
hollr::pretty_prompt(hollr::prompts$QnA)
```

    ## ROLE:
    ## 
    ## You are an instructor at a prestigious political
    ## research institute. Your role involves educating
    ## future political researchers by enhancing their
    ## understanding of political ideology, research
    ## methodology, and key findings through the
    ## development of insightful educational materials.
    ## 
    ## TASK:
    ## 
    ## You will analyze research abstracts related to
    ## political ideology in America, identify key
    ## details, and formulate Q&A pairs that challenge
    ## trainees to recognize and articulate the nuances
    ## of different studies. These questions should
    ## cover various aspects such as research questions,
    ## methodology, key findings, parties mentioned, and
    ## implications. You will convert these questions
    ## and answers into structured data formats to
    ## facilitate efficient learning and comprehension.
    ## 
    ## EXAMPLE INPUT:
    ## 
    ## Personal similarities to a transgressor makes one
    ## view the transgression as less immoral. We
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
    ## about the liberal threat.
    ## 
    ## EXAMPLE OUTPUT:
    ## 
    ## [ { "question": "What was the main hypothesis of
    ## the study?", "answer": "The main hypothesis was
    ## that increasing the personal relevance of a
    ## politically-charged threat would lead
    ## participants to report the threat as more
    ## immoral, even for threats the participant might
    ## otherwise view indifferently."  }, { "question":
    ## "How were the participants assigned in the
    ## study?", "answer": "Participants were randomly
    ## assigned to write about the personal relevance of
    ## either a liberal threat (pollution), conservative
    ## threat (disrespecting an elder), neutral threat
    ## (romantic infidelity), or given a control filler
    ## task."  }, { "question": "What were the key
    ## findings related to liberal-leaning
    ## participants?", "answer": "Liberal-leaning
    ## participants rated the conservative threat as
    ## more immoral when primed with conservative
    ## writing prompts compared to the same threat after
    ## a liberal writing prompt."  }, { "question":
    ## "What was the sample size of the study?",
    ## "answer": "The sample size of the study was 488
    ## U.S. participants."  }, { "question": "Did the
    ## study find the same results for
    ## conservative-leaning participants?", "answer":
    ## "No, the study did not find the same results for
    ## conservative-leaning participants. This may be
    ## because all participants cared relatively equally
    ## about the liberal threat."  } ]

## Cloud-based LLMs

### Force JSON

### Parallel processing

## Local LLMs

### Sequential

### Batch processing
