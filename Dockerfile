FROM node:24-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS build
WORKDIR /app
COPY . /app

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

FROM base AS api
WORKDIR /app

COPY --from=build --chown=node:node /prod/api /app
RUN mkdir -p /app/.git/logs/refs/heads && mkdir -p /app/.git/refs/heads && echo "ref: refs/heads/main" > /app/.git/HEAD && echo "0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 Test <test@test.com> 0 +0000 commit: init" > /app/.git/logs/HEAD && printf "[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n[remote \"origin\"]\n\turl = https://github.com/imput/cobalt\n" > /app/.git/config && echo "0000000000000000000000000000000000000000" > /app/.git/refs/heads/main

USER node

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
