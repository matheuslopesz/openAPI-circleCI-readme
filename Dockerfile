# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.2.0
FROM ruby:$RUBY_VERSION-slim AS base

ENV BUNDLER_VERSION=2.4.1 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    BUNDLE_PATH="/usr/local/bundle"

# Build args para UID/GID
ARG USER_ID=1000
ARG GROUP_ID=1000

# Create app directory
WORKDIR /rails

# Install minimal OS dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install bundler version
RUN gem install bundler -v $BUNDLER_VERSION

# Create group and user with matching host UID/GID
RUN groupadd -g $GROUP_ID rails && \
    useradd -m -u $USER_ID -g rails -s /bin/bash rails

# ===============================
# Build stage (instala gems, assets, etc.)
# ===============================
FROM base AS build

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV} \
    NODE_ENV=${RAILS_ENV} \
    BUNDLE_WITHOUT=""

# Extra packages to compile native gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists

# Copy only Gemfile to cache bundle layer
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy full project
COPY . .

# Precompile app code (bootsnap, etc)
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Optional: precompile assets only if RAILS_ENV=production
RUN if [ "$RAILS_ENV" = "production" ]; then \
      SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile; \
    fi

# ===============================
# Final stage
# ===============================
FROM base

ARG RAILS_ENV=development
ENV RAILS_ENV=${RAILS_ENV} \
    NODE_ENV=${RAILS_ENV}

# Copy bundle and app from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Fix ownership for runtime dirs
RUN mkdir -p /rails/tmp /rails/log /rails/storage && \
    chown -R $USER_ID:$GROUP_ID /rails
