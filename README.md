# Rails Typed API

A Rails gem to declare (or infer) request/response types in controllers and generate TypeScript interfaces and optionally OpenAPI specs.

## Installation (local path)

Add to your Rails app's Gemfile:

```ruby
gem "rails_typed_api", path: "../path/to/rails_typed_api"
```

Then bundle install.

## Quick start

1) Add declarations with the DSL (optional if using Sorbet structs):

```ruby
class Api::UsersController < ApplicationController
  typed :create,
        params: { user: { name: :string, email: :string } },
        returns: { id: :integer, name: :string }

  def create
    user = User.create!(user_params)
    render json: user
  end
end
```

2) Generate artifacts:

```bash
bin/rails typed:generate                  # writes TS to frontend/types/api_types.ts
bin/rails typed:generate -- --openapi     # also writes frontend/openapi/openapi.json
bin/rails typed:generate -- --rtk         # includes basic RTK Query API + hooks
# or via env vars
OPENAPI=1 RTK=1 bin/rails typed:generate
```

3) Configure (optional) in `config/initializers/rails_typed_api.rb`:

```ruby
RailsTypedApi.configure do |c|
  c.types_output_path = "frontend/types"
  c.openapi_output_path = "frontend/openapi"
  c.client_variant = nil # or :rtk
end
```

## What gets generated

- TypeScript interfaces/types for request/response per endpoint
- Optional OpenAPI 3.0 `paths` with requestBody + 200 response
- Optional RTK Query API boilerplate and exported hooks

## Type sources (precedence)

1) DSL macro in controllers (`typed :action, params:, returns:`)
2) Sorbet T::Structs (if present)
3) Heuristic fallback (controller → model + action rules)

### DSL

- Primitives: `:string, :integer, :boolean, :float, :uuid, :datetime`
- Arrays & nested objects are supported:

```ruby
typed :update, params: { tags: [:string], profile: { age: :integer } }, returns: { ok: :boolean }
```

### Sorbet-based types (optional & experimental)

Declare request/response DTOs as `T::Struct`s using this naming convention:

- `{ControllerBase}{Action}Request`
- `{ControllerBase}{Action}Response`

For `Api::UsersController#create`:

```ruby
# app/models/users_create_request.rb
class UsersCreateRequest < T::Struct
  const :name, String
  const :email, String
end

# app/models/users_create_response.rb
class UsersCreateResponse < T::Struct
  const :id, Integer
  const :name, String
  const :email, String
  const :created_at, Time
  const :updated_at, Time
end
```

Notes:
- App is eager-loaded during generation to discover these classes.
- Supported mappings include arrays (`T::Array[T]`), `T.nilable[T]`, simple unions (`T.any`) and nested structs.

### Heuristic fallback

When neither DSL nor Sorbet DTOs exist, we infer from the model that matches the controller name:

- `create/update`: request = model columns (excluding id/timestamps); response = full model
- `show`: response = full model
- `index`: response = array of model
- `destroy`: response = `{ success: :boolean }`

## Demo apps

- Vanilla Rails API: `examples/demo_app/`
- Sorbet-enabled Rails API: `examples/demo_app_sorbet/`

Run in each app directory:

```bash
bundle exec rails db:migrate
bundle exec rails typed:generate -- --openapi --rtk
```

### Generate for specific controllers

You can scope generation to one or more controllers using `--controller=` or the `CONTROLLER` env var. Match by full class or base name (case-insensitive). Comma-separated list is supported.

Examples:

```bash
# Only UsersController endpoints
bin/rails typed:generate -- --controller=Users

# Namespaced controller
bin/rails typed:generate -- --controller=Api::UsersController

# Multiple controllers
bin/rails typed:generate -- --controller=Users,Orders

# Using env var (also supports multiple)
CONTROLLER=Users bin/rails typed:generate
CONTROLLER="Users,Orders" bin/rails typed:generate
```

## OpenAPI

Generates a minimal OpenAPI 3.0 document featuring requestBody (when present) and a `200` response schema under `paths`.

## RTK Query (optional)

Emits a small RTK API with endpoints and exported hooks. You can copy/paste or adapt it into your app’s client layer.

## Limitations & roadmap

- No static analysis of `params.permit` or controller `render json:` yet.
- Sorbet integration uses `T::Struct` DTOs (not method `sig` annotations).
- Nested payload preference (e.g., `{ user: { ... } }`) is best expressed via DSL or a nested T::Struct.

PRs and feedback welcome!
