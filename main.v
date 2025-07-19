module main

import os
import time
import veb
import db.sqlite

// Response struct for chart data
pub struct ChartData {
    dates []string
    weights []f64
}

// Context holds request-specific data
pub struct Context {
    veb.Context
}

// App holds application-wide data
pub struct App {
    veb.Controller
    veb.StaticHandler
mut:
    db sqlite.DB // Database connection
}

fn main() {
    // Initialize the database connection
    db := sqlite.connect('tracker.db') or { panic(err) }

    // Create the database tables if they don't exist
    sql db {
        create table Goal
        create table WeightLog
        create table Measurement
    }!

    mut app := &App{
        db: db,
    }

    // Serve static files (CSS, JS, images) from the 'public' directory
    app.mount_static_folder_at('public', '/public')!

    // Start the web server
    veb.run[App, Context](mut app, 8080)
}

// The Goal struct for ORM - table name will be inferred as 'goals' (lowercase + s)
@[table: 'goals']
pub struct Goal {
    id int @[primary; sql: serial] // Auto-incrementing primary key
    goal_weight f64 @[required]
    target_date string @[required]
}

// Weight log struct for ORM
@[table: 'weight_logs']
pub struct WeightLog {
    id int @[primary; sql: serial]
    log_date string @[required]
    weight f64 @[required]
    image_path string
}

// Measurements struct for optional body measurements
@[table: 'measurements']
pub struct Measurement {
    id int @[primary; sql: serial]
    log_id int @[required; fkey: 'weight_logs(id)']
    measurement_type string @[required]
    value f64 @[required]
}

// Displays the form to set a weight goal
@[get; '/goal']
pub fn (app &App) goal_form(mut ctx Context) veb.Result {
    // This could return an HTML template
    return ctx.html('<h1>Set Your Goal</h1><form action="/goal" method="post">...</form>')
}

// Processes the submitted goal form
@[post; '/goal']
pub fn (app &App) set_goal(mut ctx Context) veb.Result {
    // 1. Get form data as strings
    goal_weight_str := ctx.form['goal_weight'] or { return ctx.request_error('Missing goal weight') }
    target_date := ctx.form['target_date'] or { return ctx.request_error('Missing target date') }

    // 2. Convert string weight to f64 for the struct, with error handling
    goal_weight := goal_weight_str.f64()

    // 3. Create an instance of the Goal struct
    new_goal := Goal{
        goal_weight: goal_weight
        target_date: target_date
        // The `id` field is omitted, as the database will generate it automatically.
    }

    // 4. Use the ORM's `insert` method instead of raw SQL
    sql app.db {
        insert new_goal into Goal
    } or {
        return ctx.server_error('Failed to save goal')
    }

    return ctx.redirect('/', typ: .see_other)
}

// Displays the form for logging weight
@[get; '/log']
pub fn (app &App) log_form(mut ctx Context) veb.Result {
    today := time.now().custom_format('YYYY-MM-DD')

    html := '
    <!DOCTYPE html>
    <html>
    <head>
        <title>Log Weight - Weight Tracker</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                margin: 40px;
                background-color: #f5f5f5;
            }
            .container {
                max-width: 600px;
                margin: 0 auto;
                background: white;
                padding: 30px;
                border-radius: 8px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            .nav { margin-bottom: 30px; }
            .nav a { margin-right: 20px; text-decoration: none; color: #0066cc; }
            .nav a:hover { text-decoration: underline; }
            .form-group { margin-bottom: 20px; }
            label {
                display: block;
                margin-bottom: 5px;
                font-weight: bold;
                color: #333;
            }
            input[type="number"], input[type="date"], input[type="file"] {
                width: 100%;
                padding: 10px;
                border: 2px solid #ddd;
                border-radius: 4px;
                font-size: 16px;
                box-sizing: border-box;
            }
            input[type="number"]:focus, input[type="date"]:focus {
                border-color: #0066cc;
                outline: none;
            }
            .measurements {
                border: 1px solid #ddd;
                padding: 20px;
                border-radius: 4px;
                background-color: #f9f9f9;
                margin-top: 20px;
            }
            .measurements h3 { margin-top: 0; color: #666; }
            .measurements .form-group { margin-bottom: 15px; }
            .measurements label { font-weight: normal; }
            button {
                background-color: #0066cc;
                color: white;
                padding: 12px 30px;
                border: none;
                border-radius: 4px;
                font-size: 16px;
                cursor: pointer;
                margin-top: 20px;
            }
            button:hover { background-color: #0052a3; }
            .required { color: red; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="nav">
                <a href="/">← Back to Dashboard</a>
                <a href="/goal">Set Goal</a>
            </div>

            <h1>Log Your Weight</h1>

            <form action="/log" method="post" enctype="multipart/form-data">
                <div class="form-group">
                    <label for="weight">Weight <span class="required">*</span></label>
                    <input type="number" id="weight" name="weight" step="0.1" min="0" max="1000" required
                           placeholder="Enter your weight (e.g., 150.5)">
                </div>

                <div class="form-group">
                    <label for="log_date">Date</label>
                    <input type="date" id="log_date" name="log_date" value="${today}">
                </div>

                <div class="form-group">
                    <label for="photo">Photo (optional)</label>
                    <input type="file" id="photo" name="photo" accept="image/*">
                    <small style="color: #666;">Upload a progress photo (JPG, PNG, etc.)</small>
                </div>

                <div class="measurements">
                    <h3>Optional Body Measurements</h3>

                    <div class="form-group">
                        <label for="body_fat">Body Fat %</label>
                        <input type="number" id="body_fat" name="body_fat" step="0.1" min="0" max="100"
                               placeholder="e.g., 15.5">
                    </div>

                    <div class="form-group">
                        <label for="waist">Waist (inches)</label>
                        <input type="number" id="waist" name="waist" step="0.1" min="0"
                               placeholder="e.g., 32.0">
                    </div>

                    <div class="form-group">
                        <label for="chest">Chest (inches)</label>
                        <input type="number" id="chest" name="chest" step="0.1" min="0"
                               placeholder="e.g., 40.0">
                    </div>

                    <div class="form-group">
                        <label for="arms">Arms (inches)</label>
                        <input type="number" id="arms" name="arms" step="0.1" min="0"
                               placeholder="e.g., 14.5">
                    </div>

                    <div class="form-group">
                        <label for="thighs">Thighs (inches)</label>
                        <input type="number" id="thighs" name="thighs" step="0.1" min="0"
                               placeholder="e.g., 22.0">
                    </div>
                </div>

                <button type="submit">Log Weight Entry</button>
            </form>
        </div>
    </body>
    </html>
    '
    return ctx.html(html)
}

// Processes the weight log form submission
@[post; '/log']
pub fn (app &App) save_log(mut ctx Context) veb.Result {
    // Get form data
    weight_str := ctx.form['weight'] or { return ctx.request_error('Missing weight') }
    log_date := ctx.form['log_date'] or { time.now().custom_format('YYYY-MM-DD') }
    mut image_path := ''

    // Convert weight string to f64
    weight := weight_str.f64()

    // Handle file upload
    if file := ctx.files['photo'][0] {
        // Define a path and save the file
        image_path = os.join_path('public', 'uploads', file.filename)
        os.write_file(image_path, file.data) or {
            return ctx.server_error('Could not save image')
        }
    }

    // Create weight log struct
    mut new_log := WeightLog{
        log_date: log_date
        weight: weight
        image_path: image_path
    }

    // Insert using V's ORM - the struct will be updated with the generated ID
    sql app.db {
        insert new_log into WeightLog
    } or {
        return ctx.server_error('Failed to save weight log: ${err}')
    }

    // The new_log.id now contains the auto-generated ID from the database
    log_id := new_log.id

    // Save optional measurements
    measurement_types := ['body_fat', 'waist', 'chest', 'arms', 'thighs']

    for measurement_type in measurement_types {
        if value_str := ctx.form[measurement_type] {
            if value_str != '' {
                value := value_str.f64()

                measurement := Measurement{
                    log_id: log_id
                    measurement_type: measurement_type
                    value: value
                }

                sql app.db {
                    insert measurement into Measurement
                } or {
                    // Continue processing other measurements even if one fails
                    eprintln('Failed to save ${measurement_type}: ${err}')
                    continue
                }
            }
        }
    }

    return ctx.redirect('/', typ: .see_other)
}

// API endpoint to provide weight data for the chart
@[get; '/api/weight-data']
pub fn (app &App) weight_data(mut ctx Context) !veb.Result {
    // A 'period' query parameter controls the time frame (e.g., '30d', '90d', 'all')
    period := ctx.query['period'] or { 'all' }

    // Query using V's ORM - simpler approach
    mut weight_logs := []WeightLog{}

    if period == 'all' {
        // Query all data
        weight_logs = sql app.db {
            select from WeightLog order by log_date
        }!
    } else {
        // Calculate the date filter based on period
        days := match period {
            '7d' { 7 }
            '30d' { 30 }
            '90d' { 90 }
            '180d' { 180 }
            '365d' { 365 }
            else { 30 } // default to 30 days
        }

        cutoff_date := time.now().add_days(-days).custom_format('YYYY-MM-DD')

        // Query with date filter - use string interpolation
        weight_logs = sql app.db {
            select from WeightLog where log_date >= '${cutoff_date}' order by log_date
        }!
    }

    // Convert ORM results to chart data structure
    chart_data := ChartData{
        dates: weight_logs.map(it.log_date)
        weights: weight_logs.map(it.weight)
    }

    // Return JSON response
    return ctx.json(chart_data)
}

// Home page - displays the main dashboard
@[get; '/']
pub fn (app &App) index(mut ctx Context) veb.Result {
    // Fetch recent weight logs for the activity list
    recent_logs := sql app.db {
        select from WeightLog order by log_date desc limit 10
    } or {
        []WeightLog{} // Return empty array on error
    }

    // Load and render template
    template_path := os.join_path('templates', 'index.html')
    template_content := os.read_file(template_path) or {
        return ctx.server_error('Could not load template')
    }

    // Simple template variable replacement
    mut html := template_content
    html = html.replace('{{RECENT_ACTIVITIES}}', generate_recent_activities_html(recent_logs))

    return ctx.html(html)
}

// Helper function to generate recent activities HTML
fn generate_recent_activities_html(logs []WeightLog) string {
    if logs.len == 0 {
        return '<p>No weight logs yet. <a href="/log">Log your first weight!</a></p>'
    }

    mut activities_html := '<ul class="activity-list">'
    for log in logs {
        image_indicator := if log.image_path != '' { '📷' } else { '' }
        activities_html += '
            <li class="activity-item">
                <a href="/log/${log.id}" class="activity-link">
                    <span class="date">${log.log_date}</span>
                    <span class="weight">${log.weight} lbs</span>
                    <span class="image-indicator">${image_indicator}</span>
                </a>
            </li>'
    }
    activities_html += '</ul>'

    return activities_html
}

// Detail view for individual weight log entries
@[get; '/log/:id']
pub fn (app &App) log_detail(mut ctx Context, id int) veb.Result {
    // Fetch the specific weight log
    logs := sql app.db {
        select from WeightLog where id == id
    } or {
        return ctx.server_error('Database error: ${err}')
    }

    if logs.len == 0 {
        return ctx.not_found()
    }

    log := logs[0]

    // Fetch associated measurements
    measurements := sql app.db {
        select from Measurement where log_id == id
    } or {
        []Measurement{} // Empty array on error
    }

    // Load detail template
    template_path := os.join_path('templates', 'log_detail.html')
    template_content := os.read_file(template_path) or {
        return ctx.server_error('Could not load template')
    }

    mut html := template_content
    html = html.replace('{{LOG_DATE}}', log.log_date)
    html = html.replace('{{WEIGHT}}', log.weight.str())
    html = html.replace('{{IMAGE_PATH}}', log.image_path)
    html = html.replace('{{HAS_IMAGE}}', if log.image_path != '' { 'true' } else { 'false' })
    html = html.replace('{{MEASUREMENTS}}', generate_measurements_html(measurements))

    return ctx.html(html)
}

// Helper function to generate measurements HTML
fn generate_measurements_html(measurements []Measurement) string {
    if measurements.len == 0 {
        return '<p>No measurements recorded for this entry.</p>'
    }

    mut html := '<div class="measurements-grid">'
    for measurement in measurements {
        // Format the measurement type (convert underscore to space and capitalize)
        formatted_type := measurement.measurement_type.replace('_', ' ').title()
        html += '
            <div class="measurement-item">
                <label>${formatted_type}</label>
                <value>${measurement.value}</value>
            </div>'
    }
    html += '</div>'

    return html
}

