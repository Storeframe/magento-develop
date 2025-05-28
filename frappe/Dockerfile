FROM frappe/erpnext:v15

# Install payments and webshop apps
RUN bench get-app payments --branch version-15 &&\
    bench get-app webshop --branch version-15