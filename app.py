# app.py
from flask import Flask, render_template, jsonify, request
from datetime import datetime
import json

app = Flask(__name__)

# Sample data - in a real app, this would come from a database
projects = [
    {
        "id": "1",
        "name": "Web Application Security Assessment",
        "client": "TechCorp Inc",
        "startDate": "2024-11-20",
        "endDate": "2024-12-20",
        "status": "planning",
        "type": "webapp",
        "priority": "high",
        "assignedTesters": [
            {
                "testerId": "T1",
                "role": "lead",
                "status": "accepted"
            }
        ]
    }
]

@app.route('/')
def dashboard():
    return render_template('dashboard.html', projects=projects)

@app.route('/api/projects', methods=['GET'])
def get_projects():
    return jsonify(projects)

@app.route('/api/projects', methods=['POST'])
def add_project():
    project = request.json
    projects.append(project)
    return jsonify({"message": "Project added successfully"}), 201

if __name__ == '__main__':
    app.run(debug=True)