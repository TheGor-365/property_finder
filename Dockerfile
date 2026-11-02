# Self-contained Railway image: Ruby 3.4 / Rails 8.1 / Node 22 asset build.
# Upload media is NOT bundled; production requires its own persistent volume.
FROM node:22-bookworm-slim AS node22

FROM ruby:3.4.12-bookworm AS build
COPY --from=node22 /usr/local/bin/node /usr/local/bin/node
COPY --from=node22 /opt/ /opt/
RUN yarn_bin="$(find /opt -type f -path '*/bin/yarn' -print -quit)" \
    && test -n "$yarn_bin" \
    && printf '#!/bin/sh\nexec "%s" "$@"\n' "$yarn_bin" > /usr/local/bin/yarn \
    && chmod +x /usr/local/bin/yarn

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential libpq-dev imagemagick libyaml-dev pkg-config git \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV BUNDLE_WITHOUT=development:test BUNDLE_DEPLOYMENT=true
RUN gem install bundler -v 2.6.9 --no-document
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .
# Build-only dummy settings, never copied as production ENV.
RUN APP_HOST=build.example.invalid \
    DATABASE_URL=postgresql://build:build@127.0.0.1/build \
    SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production \
    bundle exec rails assets:precompile

FROM ruby:3.4.12-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends \
      libpq5 imagemagick \
    && rm -rf /var/lib/apt/lists/*
ENV RAILS_ENV=production BUNDLE_WITHOUT=development:test BUNDLE_DEPLOYMENT=true \
    RAILS_LOG_TO_STDOUT=1 RAILS_SERVE_STATIC_FILES=1
WORKDIR /app
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
COPY bin/production-entrypoint /usr/local/bin/property-finder-entrypoint
RUN chmod +x /usr/local/bin/property-finder-entrypoint
EXPOSE 3000
ENTRYPOINT ["/usr/local/bin/property-finder-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
