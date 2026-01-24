ARG ELASTICSEARCH_VERSION=8.17.0
FROM elasticsearch:${ELASTICSEARCH_VERSION}

# Install Magento-required plugins
RUN bin/elasticsearch-plugin install --batch analysis-phonetic && \
    bin/elasticsearch-plugin install --batch analysis-icu
