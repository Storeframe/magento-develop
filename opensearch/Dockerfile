ARG OPENSEARCH_VERSION=2
FROM opensearchproject/opensearch:${OPENSEARCH_VERSION}

# Install Magento-required plugins
RUN bin/opensearch-plugin install --batch analysis-phonetic && \
    bin/opensearch-plugin install --batch analysis-icu
