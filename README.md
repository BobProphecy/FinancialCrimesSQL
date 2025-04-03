## Models

1. **FinancialCrimesScoring**
Scored wire transfers




## Source / Seeds

1. **WIRE_TRANSFERS**
Records of wire transfers, capturing details about sender and recipient accounts, transaction amounts, and originating and destination countries.

2. **COUNTRY_WATCHLIST**
List of countries and associated issues, aiding in monitoring and risk assessment.

3. **INDIVIDUAL_WATCHLIST**
List of individuals under scrutiny, aiding in risk management and compliance efforts.


```markdown
## Functions / Gems

1. **CamelCaseFullName**

The **CamelCaseFullName** custom method is designed to create a camel-cased string by concatenating a person's first name with their last name. By executing this method, we generate a formatted full name that adheres to the camel case convention. This can be particularly useful in scenarios where standardized naming conventions are required, such as generating variable or column names.

2. **sum_of_digits**

The **sum_of_digits** custom method offers a straightforward way to obtain the sum of the individual digits of a given number. By applying this method, we efficiently compute the total sum of the digits present within the provided number. This can be useful in various applications, such as validating and processing numerical data that requires digit-level analysis.

3. **generate_schema_name**

The **generate_schema_name** macro is a versatile tool designed to streamline the process of schema name generation in your SQL environment. This macro allows users to specify a custom schema name or defaults to the current target schema if no custom name is provided. By utilizing this macro, you can ensure consistency and clarity in your database structure, making it easier to manage and reference schemas across various projects. The macro effectively trims any unnecessary whitespace from the custom schema name, enhancing data integrity and preventing potential errors in schema referencing.
```