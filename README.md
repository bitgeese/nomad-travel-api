# Travel Tracker API

A Django REST Framework API for tracking travel and visa compliance, particularly focusing on Schengen visa rules.

## Features

- User authentication (email/password and Sign in with Apple)
- Track travel segments with entry and exit dates
- Calculate visa compliance (Schengen 90/180 day rule)
- Import travel history from CSV files (asynchronous processing)
- RESTful API with comprehensive documentation

## Technology Stack

- **Backend Framework**: Django + Django REST Framework
- **Database**: PostgreSQL
- **Asynchronous Tasks**: Redis Queue (RQ)
- **Authentication**: JWT (JSON Web Tokens)
- **Documentation**: DRF Spectacular (OpenAPI/Swagger)
- **Deployment**: Docker containers

## Development Setup

### Prerequisites

- Docker and Docker Compose
- Python 3.12+

### Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/travel-tracker-api.git
   cd travel-tracker-api
   ```

2. Start the development environment:
   ```bash
   docker-compose up --build
   ```

3. Access the API at http://localhost:8000/
4. View API documentation at http://localhost:8000/api/schema/swagger-ui/

### Development Commands

- Run migrations:
  ```bash
  docker-compose exec web python manage.py migrate
  ```

- Create a superuser:
  ```bash
  docker-compose exec web python manage.py createsuperuser
  ```

- Run tests:
  ```bash
  docker-compose exec web python manage.py test
  ```

## Project Structure

- `core/` - Base application with shared utilities
- `travel_tracker_api/` - Main project folder with settings
- `users/` - User authentication and profile management
- `travel/` - Travel segment management
- `visa_rules/` - Visa compliance calculation logic
- `countries/` - Country data and management

## License

This project is licensed under the MIT License - see the LICENSE file for details. 