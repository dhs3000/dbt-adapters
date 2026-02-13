{%- macro bigquery__scalar_function_create_replace_signature_description(target_relation) -%}
    {%- set model_description -%}
        {%- if model.description -%}
            {{ model.description.strip() }}{% if not model.description.strip().endswith('.') %}.{% endif %}
        {%- endif -%}
    {%- endset -%}
    {%- set args_description -%}
        {%- for arg in model.arguments -%}
            {%- if arg.description -%}
                - {{ arg.name }}: {{ arg.description }}{% if not arg.description.strip().endswith('.') %}.{% endif %}{% if not loop.last %} {% endif %}
            {%- endif -%}
        {%- endfor -%}
    {%- endset -%}
    {%- set description -%}
        {% if model_description %}{{ model_description }}{% endif %} {% if args_description %}Arguments: {{ args_description }}{% endif %} {% if model.returns.description %}Returns: {{ model.returns.description }}{% endif %}
    {%- endset -%}
    {{- description.replace('\n', ' ').replace('\r', '').strip() -}}
{%- endmacro -%}

{% macro bigquery__scalar_function_create_replace_signature_sql(target_relation) %}
    CREATE OR REPLACE FUNCTION {{ target_relation.render() }} ({{ formatted_scalar_function_args_sql()}})
    RETURNS {{ model.returns.data_type }}
    {% set description = bigquery__scalar_function_create_replace_signature_description(target_relation) %}
    OPTIONS({% if description %}description = "{{ description }}"{% endif %})
    {{ scalar_function_volatility_sql() }}
    AS
{% endmacro %}

{% macro bigquery__scalar_function_body_sql() %}
    (
       {{ model.compiled_code }}
    )
{% endmacro %}

{% macro bigquery__scalar_function_volatility_sql() %}
    {% set volatility = model.config.get('volatility') %}
    {% if volatility != None %}
        {% do unsupported_volatility_warning(volatility) %}
    {% endif %}
{% endmacro %}

{% macro bigquery__scalar_function_create_replace_signature_python(target_relation) %}
    CREATE OR REPLACE FUNCTION {{ target_relation.render() }} ({{ formatted_scalar_function_args_sql()}})
    RETURNS {{ model.returns.data_type }}
    LANGUAGE python
    {% set description = bigquery__scalar_function_create_replace_signature_description(target_relation) %}
    OPTIONS(runtime_version = "{{ 'python-' ~ model.config.get('runtime_version') }}", entry_point = "{{ model.config.get('entry_point') }}"{% if description %}, description = "{{ description }}"{% endif %})
    {{ scalar_function_volatility_sql() }}
    AS
{% endmacro %}

{% macro bigquery__get_scalar_function_body_python() %}
    r'''
{{ model.compiled_code }}
    '''
{% endmacro %}

{% macro bigquery__scalar_function_python(target_relation) %}
    {{ bigquery__scalar_function_create_replace_signature_python(target_relation) }}
    {{ bigquery__get_scalar_function_body_python() }}
{% endmacro %}
