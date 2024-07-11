def initialize_model(model_name):
    """
    Initialize a text generation model using the Hugging Face transformers library.

    Args:
        model_name (str): The name of the pre-trained model to load.

    Returns:
        pipeline: A text generation pipeline using the specified model and tokenizer.
    """
    # Import necessary libraries
    import os
    from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
    import torch

    # Load the tokenizer for the specified model
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    
    # Load the model with specific configurations
    model = AutoModelForCausalLM.from_pretrained(
        model_name,
        torch_dtype=torch.float16,           # Use float16 for faster inference
        attn_implementation="flash_attention_2", # Use flash attention 2 for better performance
        device_map="cuda:0"                  # Map the model to the first CUDA device (GPU)
    )
    
    # Create a text generation pipeline with the model and tokenizer
    model_pipeline = pipeline(
        "text-generation",
        model=model,
        tokenizer=tokenizer
    )
    
    return model_pipeline  # Return the text generation pipeline


def generate_text(model_pipeline, 
                  prompt, 
                  temp, 
                  max_length, 
                  max_new_tokens=None, 
                  max_attempts=20, 
                  is_json_output=True):
    """
    Generate text using the specified text generation pipeline.

    Args:
        model_pipeline (pipeline): The text generation pipeline.
        prompt (str): The input prompt to generate text from.
        temp (float): The temperature for text generation (controls randomness).
        max_length (int): The maximum length of the generated text.
        max_new_tokens (int, optional): The maximum number of new tokens to generate.
        max_attempts (int): The maximum number of attempts for generating text.
        is_json_output (bool): Whether to return the output as JSON (default: True).

    Returns:
        str: The generated text.
    """
    from transformers import pipeline

    try:
        # Set max_new_tokens if specified, otherwise use max_length
        generation_kwargs = {
            "max_new_tokens": max_new_tokens if max_new_tokens is not None else max_length,
            "temperature": temp,               # Set the temperature for randomness
            "do_sample": True,                 # Enable sampling for text generation
            "return_full_text": False,         # Only return the generated text, not the prompt
            "num_return_sequences": 1,         # Generate a single sequence
            "eos_token_id": model_pipeline.tokenizer.eos_token_id,  # End of sequence token
            "pad_token_id": model_pipeline.tokenizer.eos_token_id   # Padding token
        }
        
        # Generate text using the pipeline with the specified parameters
        sequences = model_pipeline(prompt, **generation_kwargs)
        
        # Extract the generated text from the output sequences
        generated_text = [seq['generated_text'] for seq in sequences][0]

        return generated_text  # Return the generated text
    except Exception as e:
        print(f"An error occurred: {e}")  # Print the error message
        return None  # Return None if an error occurs
