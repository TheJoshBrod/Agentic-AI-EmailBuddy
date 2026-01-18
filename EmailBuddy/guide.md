# Jac Client - Full-Stack Development Guide

## Overview

This documentation page explains **Jac Client**, a full-stack web development framework that allows developers to build complete web applications using a single language called **Jac** for both frontend and backend development.

## What is Jac Client?

Jac Client is a framework that provides React-style components with JSX syntax, state management, and seamless backend integration - all using the Jac programming language. It eliminates the traditional complexity of managing separate frontend and backend codebases.

### Key Advantages

| Traditional Stack | Jac Full-Stack |
|-------------------|----------------|
| Separate frontend/backend languages (e.g., JavaScript + Python) | Single language for everything |
| HTTP boilerplate (fetch, axios) | Direct walker calls via `spawn` |
| Manual API integration | Seamless frontend-backend bridge |
| Separate type systems | Type safety across boundaries |

## Getting Started

### Quick Setup

```bash
# Create a new full-stack project
jac create --cl myapp
cd myapp
jac start
```

After running these commands, visit `http://localhost:8000/cl/app` to see your application.

### Project Structure

```
myapp/
├── jac.toml              # Configuration file
├── main.jac              # Main entry point (frontend + backend)
├── components/           # Reusable components (TypeScript/JSX)
│   └── Button.cl.jac        # Example component
├── assets/               # Static files (images, fonts)
└── .jac/                 # Build artifacts (gitignored)
```

## Core Concepts

### 1. Basic Components

Components in Jac Client use a special `cl { }` block to mark frontend code:

```jac
cl {
    def:pub app() -> any {
        has count: int = 0;

        return <div>
            <h1>Count: {count}</h1>
            <button onClick={lambda -> None { count = count + 1; }}>
                Increment
            </button>
        </div>;
    }
}
```

**Key Points:**
- `cl { }` blocks mark frontend code
- `def:pub app()` is the required entry point
- `has` variables are automatically reactive (generates React useState)

### 2. State Management

#### Reactive State with `has`

Inside client blocks (`.cl.jac` files), `has` variables automatically become React state:

```jac
cl {
    def:pub Counter() -> any {
        has count: int = 0;
        has name: str = "World";

        return <div>
            <h1>Hello, {name}! Count: {count}</h1>
            <input
                value={name}
                onChange={lambda e: any -> None { name = e.target.value; }}
            />
            <button onClick={lambda -> None { count = count + 1; }}>+1</button>
        </div>;
    }
}
```

The compiler automatically:
- Generates `useState` calls
- Auto-injects the `useState` import from `@jac-client/utils`
- Transforms assignments to setter calls

#### useEffect Hook

For side effects and lifecycle management:

```jac
cl {
    import from react { useEffect }

    def:pub DataLoader() -> any {
        has data: list = [];

        # Run once on mount
        useEffect(lambda -> None {
            async def load() -> None {
                result = root spawn get_items();
                data = result.reports;
            }
            load();
        }, []);

        return <ul>
            {data.map(lambda item: any -> any {
                return <li key={item._jac_id}>{item.name}</li>;
            })}
        </ul>;
    }
}
```

#### useContext (Global State)

For sharing state across components:

```jac
cl {
    import from react { createContext, useContext }

    AppContext = createContext(None);

    def:pub AppProvider(props: dict) -> any {
        has user: any = None;

        return <AppContext.Provider value={{ "user": user, "setUser": lambda v: any -> None { user = v; } }}>
            {props.children}
        </AppContext.Provider>;
    }

    def:pub UserDisplay() -> any {
        ctx = useContext(AppContext);
        return <div>User: {ctx.user or "Not logged in"}</div>;
    }
}
```

### 3. Backend Integration

One of Jac's most powerful features is the seamless integration between frontend and backend.

#### Define Backend Walker

"Walkers" are Jac's way of defining backend logic:

```jac
# Backend code (outside cl block)
node Todo {
    has text: str;
    has done: bool = False;
}

walker create_todo {
    has text: str;

    can create with `root entry {
        new_todo = here ++> Todo(text=self.text);
        report new_todo;
    }
}

walker get_todos {
    can fetch with `root entry {
        for todo in [-->(`?Todo)] {
            report todo;
        }
    }
}
```

#### Call from Frontend

Frontend components can call backend walkers directly:

```jac
cl {
    import from react { useEffect }

    def:pub TodoApp() -> any {
        has todos: list = [];
        has text: str = "";

        # Load todos on mount
        useEffect(lambda -> None {
            async def load() -> None {
                result = root spawn get_todos();
                todos = result.reports;
            }
            load();
        }, []);

        # Add todo handler
        def add_todo() -> None {
            async def create() -> None {
                result = root spawn create_todo(text=text);
                todos = [...todos, result.reports[0]];
                text = "";
            }
            create();
        }

        return <div>
            <input value={text} onChange={lambda e: any -> None { text = e.target.value; }} />
            <button onClick={lambda -> None { add_todo(); }}>Add</button>
            <ul>
                {todos.map(lambda t: any -> any {
                    return <li key={t._jac_id}>{t.text}</li>;
                })}
            </ul>
        </div>;
    }
}
```

### 4. Routing

Jac Client includes built-in routing capabilities:

```jac
cl {
    import from "@jac-client/utils" { Router, Routes, Route, Link, useParams, useNavigate }

    def:pub Home() -> any {
        return <div>
            <h1>Home</h1>
            <Link to="/about">About</Link>
            <Link to="/user/123">User 123</Link>
        </div>;
    }

    def:pub About() -> any {
        return <h1>About Page</h1>;
    }

    def:pub UserProfile() -> any {
        params = useParams();
        return <h1>User: {params.id}</h1>;
    }

    def:pub app() -> any {
        return <Router>
            <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/about" element={<About />} />
                <Route path="/user/:id" element={<UserProfile />} />
            </Routes>
        </Router>;
    }
}
```

**Available Routing Hooks:**
- `useNavigate()`: Programmatic navigation
- `useLocation()`: Current pathname, search, hash
- `useParams()`: URL parameters (`:id`)

### 5. Authentication

Built-in authentication utilities:

```jac
cl {
    import from "@jac-client/utils" {
        jacLogin, jacSignup, jacLogout, jacIsLoggedIn
    }

    def:pub LoginForm() -> any {
        has username: str = "";
        has password: str = "";
        has error: str = "";

        def handle_login() -> None {
            async def login() -> None {
                success = await jacLogin(username, password);
                if success {
                    print("Logged in!");
                } else {
                    error = "Login failed";
                }
            }
            login();
        }

        return <div>
            <input placeholder="Username" value={username}
                   onChange={lambda e: any -> None { username = e.target.value; }} />
            <input type="password" placeholder="Password" value={password}
                   onChange={lambda e: any -> None { password = e.target.value; }} />
            <button onClick={lambda -> None { handle_login(); }}>Login</button>
            {error and <p style={{"color": "red"}}>{error}</p>}
        </div>;
    }

    def:pub ProtectedRoute(props: dict) -> any {
        if not jacIsLoggedIn() {
            return <Navigate to="/login" />;
        }
        return props.children;
    }
}
```

## Styling Options

### 1. Inline Styles

```jac
cl {
    def:pub StyledButton() -> any {
        return <button style={{
            "backgroundColor": "blue",
            "color": "white",
            "padding": "10px 20px",
            "borderRadius": "5px"
        }}>
            Click Me
        </button>;
    }
}
```

### 2. CSS Files

```jac
cl {
    import ".styles.css"

    def:pub MyComponent() -> any {
        return <div className="container">
            <h1 className="title">Hello</h1>
        </div>;
    }
}
```

### 3. Tailwind CSS

Configure in `jac.toml` and use directly:

```jac
cl {
    def:pub TailwindComponent() -> any {
        return <div className="bg-blue-500 text-white p-4 rounded-lg">
            Tailwind Styled
        </div>;
    }
}
```

## TypeScript Integration

Jac Client can work with TypeScript components:

```jac
cl {
    # Import TypeScript components
    import from ".Button.tsx" { Button }

    def:pub app() -> any {
        return <div>
            <Button label="Click me" onClick={lambda -> None { print("Clicked!"); }} />
        </div>;
    }
}
```

## Package Management

### Adding npm Packages

```bash
# Add npm packages
jac add --cl lodash
jac add --cl --dev @types/react

# Remove packages
jac remove --cl lodash

# Install all dependencies
jac add --cl
```

### Configuration in jac.toml

```toml
[dependencies.npm]
lodash = "^4.17.21"
axios = "^1.6.0"

[dependencies.npm.dev]
sass = "^1.77.8"
```

## File Organization

### Separate Files Approach

```
src/
├── app.jac           # Backend (nodes, walkers)
├── app.cl.jac        # Frontend (no cl block needed)
├── components/
│   ├── Button.jac
│   └── Modal.jac
└── pages/
    ├── Home.jac
    └── About.jac
```

### Mixed in Single File

```jac
# Backend code
node Todo { has text: str; }
walker get_todos { ... }

# Frontend code
cl {
    def:pub app() -> any {
        # Uses backend walkers directly
        result = root spawn get_todos();
        ...
    }
}
```

## Build Commands

```bash
# Development server (uses main.jac by default)
jac start

# Start with specific file
jac start app.jac

# Production build
jac build main.jac
```

## Hot Module Replacement (HMR)

For faster development, use `--watch` mode:

### Setup

Ensure `watchdog` is installed:

```toml
[dev-dependencies]
watchdog = ">=3.0.0"
```

```bash
jac install --dev
```

### Development Workflow

```bash
# Start with HMR enabled
jac start --watch
```

This starts:
- **Vite dev server** on port 8000 (open in browser)
- **API server** on port 8001 (proxied via Vite)
- **File watcher** monitoring `*.jac` files

When you edit a `.jac` file:
1. File watcher detects the change
2. Backend code is recompiled automatically
3. Frontend hot-reloads via Vite
4. Browser updates without full page refresh

### HMR Options

| Option | Description |
|--------|-------------|
| `--watch, -w` | Enable HMR mode |
| `--api-port PORT` | Custom API port (default: main port + 1) |
| `--no-client` | API-only mode (skip Vite/frontend) |

## Exports (`:pub` keyword)

For jac-client >= 0.2.4, use `:pub` to export:

```jac
cl {
    # Exported function
    def:pub MyComponent() -> any { ... }

    # Exported variable
    glob:pub API_URL: str = "https://api.example.com";

    # Not exported (internal use only)
    def helper() -> any { ... }
}
```

## Learning Path

The documentation suggests this tutorial progression:

1. **Project Setup** - Initial configuration
2. **First Component** - Creating basic components
3. **Styling** - Different styling approaches
4. **State Management** - Managing component state
5. **Backend Integration** - Connecting to walkers
6. **Authentication** - User authentication flows
7. **Routing** - Client-side navigation

## Key Features Summary

- **Single Language**: Use Jac for both frontend and backend
- **React-like Components**: JSX syntax with reactive state management
- **Seamless Backend Calls**: Direct walker invocation from frontend
- **Built-in Routing**: Client-side routing out of the box
- **Authentication**: Pre-built auth utilities
- **TypeScript Support**: Interoperability with TypeScript
- **Hot Module Replacement**: Fast development workflow
- **Multiple Styling Options**: Inline, CSS files, or Tailwind
- **Type Safety**: End-to-end type checking

## Related Resources

- Full documentation: https://docs.jaseci.org/
- Jac Programming Language Guide
- Object-Spatial Programming (OSP) concepts
- byLLM (AI integration)
- Jac Scale (production deployment)

---

This framework represents a modern approach to full-stack development, reducing context switching and improving developer productivity by unifying the entire stack under a single language and paradigm.