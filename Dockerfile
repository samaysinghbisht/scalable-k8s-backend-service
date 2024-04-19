# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY app/requirements.txt ./

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

#Copy the environment variables
COPY .env .

# Copy the rest of your application's code
COPY app/ .

# Make port 5001 available to the world outside this container
EXPOSE 5001

# Define environment variable
ENV NAME BACKEND-SVC

# Run app.py when the container launches
CMD ["python", "app.py"]
