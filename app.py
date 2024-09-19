from flask import Flask, request, jsonify
import mysql.connector
import uuid
from decimal import Decimal

app = Flask(__name__)

# MySQL Database connection
db_config = {
    'user': 'root',
    'password': 'root',
    'host': 'localhost',  # Or the database host
    'database': 'bakerydb',
}

# Function to get a database connection
def get_db_connection():
    return mysql.connector.connect(**db_config)

# Function to retrieve menu items from the database
def get_menu_from_db():
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    # SQL query to fetch food items
    cursor.execute("SELECT name, price FROM food_items")
    menu_items = cursor.fetchall()
    
    cursor.close()
    connection.close()
    return menu_items

# Function to retrieve order details from the database
def get_order_details(order_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    # Query to retrieve order details
    query = """
        SELECT orders.item_id, food_items.name, orders.quantity, orders.total_price
        FROM orders
        JOIN food_items ON orders.item_id = food_items.item_id
        WHERE orders.order_id = %s
    """
    
    cursor.execute(query, (order_id,))
    result = cursor.fetchall()

    cursor.close()
    conn.close()

    if result:
        # Format the result into a readable message
        order_details = []
        for row in result:
            item_id, name, quantity, total_price = row
            order_details.append(f"Item: {name}, Quantity: {quantity}, Total Price: ${total_price:.2f}")
        
        return "\n".join(order_details)
    else:
        return "No order found with this ID."

# Flask route to handle the intents
@app.route('/webhook', methods=['POST'])
def webhook():
    try:
        req = request.get_json(silent=True, force=True)
        
        # Debugging: Print request data
        print("Request data:", req)
        
        # Check the intent name
        intent_name = req.get('queryResult').get('intent').get('displayName')
        
        if intent_name == 'menu':
            # Fetch menu from the database
            menu_items = get_menu_from_db()
            
            # Create response text
            response_text = "Here's our menu:\n"
            for item in menu_items:
                response_text += f"{item['name']} - ${item['price']}\n"
            
            # Return the response to Dialogflow
            return jsonify({
                "fulfillmentText": response_text
            })
        
        elif intent_name == 'new.order':
            # Generate a new unique order ID using UUID
            new_order_id = str(uuid.uuid4())
            
            # Prepare the response text
            response_text = f"Your new order has been created with order ID {new_order_id}. What would you like to order?"
            
            # Extract the session ID
            session_id = req.get('session').split('/')[-1]
            
            # Prepare the context name
            context_name = f"projects/your-project-id/agent/sessions/{session_id}/contexts/order_context"
            
            # Store order ID in session context (Dialogflow session parameters)
            return jsonify({
                "fulfillmentText": response_text,
                "outputContexts": [
                    {
                        "name": context_name,
                        "lifespanCount": 5,
                        "parameters": {
                            "order_id": new_order_id
                        }
                    }
                ]
            })
        
        elif intent_name == 'order.add':
            # Extract parameters from the request
            item_name = req.get('queryResult').get('parameters').get('menu_items', '').strip()
            quantity = int(req.get('queryResult').get('parameters').get('number', 1))
            
            # Debugging: Print extracted parameters
            print("Item Name:", item_name)
            print("Quantity:", quantity)
            
            # Get the order ID from session parameters
            session_id = req.get('session').split('/')[-1]
            order_id = req.get('queryResult').get('outputContexts')[0]['parameters'].get('order_id', '')
            
            # Handle case where order_id is missing
            if not order_id:
                return jsonify({"fulfillmentText": "No active order found. Please start a new order first."})
            
            # Insert the item into the orders table
            conn = get_db_connection()
            cursor = conn.cursor()
            
            # Normalize the item name (e.g., remove leading/trailing spaces and convert to lower case)
            cursor.execute("SELECT item_id, price FROM food_items WHERE LOWER(name) = %s", (item_name.lower(),))
            item = cursor.fetchone()
            
            # Debugging: Print fetched item details
            print("Fetched Item:", item)
            
            if item:
                item_id, price = item
                # Convert Decimal to float for calculation
                if isinstance(price, Decimal):
                    price = float(price)
                
                total_price = price * quantity
                
                # Insert order item
                cursor.execute("INSERT INTO orders (order_id, item_id, quantity, total_price) VALUES (%s, %s, %s, %s)",
                               (order_id, item_id, quantity, total_price))
                conn.commit()
                
                response_text = f"Added {quantity} {item_name} to your order."
            else:
                response_text = f"Item {item_name} not found."
            
            cursor.close()
            conn.close()
            
            # Return the response
            return jsonify({
                "fulfillmentText": response_text
            })
        
        elif intent_name == 'order.complete':
            # Get the full order_id from parameters
            order_id = req.get('queryResult').get('queryText')  # Use queryText for UUID input
            
            # Get the order details
            order_details = get_order_details(order_id)
            
            # Create the response to send back to Dialogflow
            response = {
                'fulfillmentText': f"Here are the details for order ID {order_id}:\n{order_details}"
            }
            
            return jsonify(response)
        
        else:
            return jsonify({"fulfillmentText": "Intent not recognized."})
    
    except Exception as e:
        # Debugging: Print any errors
        print("Error:", str(e))
        return jsonify({"fulfillmentText": "An error occurred."})

if __name__ == '__main__':
    app.run(port=5000, debug=True)
