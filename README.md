

# Bakery Chatbot

This project is a chatbot-based ordering system for a bakery. The chatbot interacts with customers, allowing them to view the menu, place orders, and track order status in real-time.

## Features

- **Menu Display**: Customers can view all available bakery items with their prices.
- **Order Management**: Customers can create new orders, add/remove items, and complete orders.
- **Order Tracking**: Tracks and updates the status of orders (e.g., in transit, delivered).
- **Backend Integration**: Uses Flask API and MySQL for order and menu management.

## Prerequisites

Before running this project, ensure you have the following installed:

- Python 3.x
- Flask
- MySQL
- Ngrok (for exposing your local API)
- Dialogflow (for chatbot interactions)

## Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/Nikhil-Pawar11/Dialogflow-Bakery-Chatbot.git

2. Install the required Python packages:

    ```bash
    pip install -r requirements.txt

3. Set up the MySQL database:.


    - Import the provided SQL script from the sql/ folder to set up the necessary database tables.
    - Use the script to create the bakerydb database and set up the tables (food_items, orders, order_tracking).

5. Update the MySQL connection details in the app.py file with your database credentials.

## Usage Instructions

1. Start the Flask server:

    ```bash
    flask run

2. Interact with the chatbot via Dialogflow by configuring it to use the appropriate webhooks provided by your Flask server.

3. If using Ngrok, you can expose your local Flask server by running:

        ngrok http 5000





## Database Setup
- Run the following SQL commands (or import the provided bakery_chatbot.sql file) to create the database
     
        CREATE DATABASE IF NOT EXISTS bakerydb;

        USE bakerydb;

        -- Create food_items, orders, and order_tracking tables as described in the provided SQL script.



## API Documentation

The project provides a RESTful API to handle orders. Below are some example endpoints:

- Get Menu: /webhook (POST request via Dialogflow to retrieve menu items)
- Create New Order: /webhook (POST request to generate a new order ID)
- Add Item to Order: /webhook (POST request to add items to the order)
- Complete Order: /webhook (POST request to fetch order details and finalize the order)

## Sample Requests

- ### Menu Request:

    The chatbot responds with the list of items and prices from the menu stored in the database.

- ### New Order Request:

    After initiating an order, a unique order ID is generated and returned to the user.

- ### Order Completion:

    After completing an order, the user is prompted to enter their order ID to retrieve details.


## Contribution Guidelines


Feel free to submit issues or pull requests. Contributions are always welcome.

