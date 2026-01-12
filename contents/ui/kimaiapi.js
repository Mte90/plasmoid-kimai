// Library for Kimai API calls
.pragma library

/**
 * Create and configure XMLHttpRequest with authentication
 * @param {string} method - HTTP method (GET, POST, PATCH, etc.)
 * @param {string} kimaiUrl - The Kimai server URL
 * @param {string} endpoint - API endpoint path
 * @param {string} apiToken - The API token
 * @param {boolean} isJson - Whether to set Content-Type to application/json
 * @returns {XMLHttpRequest} Configured XMLHttpRequest object
 */
function createAuthenticatedRequest(method, kimaiUrl, endpoint, apiToken, isJson) {
    var xhr = new XMLHttpRequest()
    xhr.open(method, kimaiUrl + endpoint, true)
    xhr.setRequestHeader("Authorization", "Bearer " + apiToken)
    if (isJson) {
        xhr.setRequestHeader("Content-Type", "application/json")
    }
    return xhr
}

/**
 * Test connection to Kimai server
 * @param {string} kimaiUrl - The Kimai server URL
 * @param {string} apiToken - The API token
 * @param {function} callback - Callback function (success: boolean, message: string)
 */
function testConnection(kimaiUrl, apiToken, callback) {
    if (!kimaiUrl || !apiToken) {
        callback(false, "URL and API token are required")
        return
    }

    var xhr = createAuthenticatedRequest("GET", kimaiUrl, "/api/version", apiToken, false)
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText)
                    callback(true, "Connected successfully! Kimai version: " + (response.version || "unknown"))
                } catch (e) {
                    callback(true, "Connected successfully!")
                }
            } else if (xhr.status === 401) {
                callback(false, "Authentication failed. Please check your API token.")
            } else if (xhr.status === 404) {
                callback(false, "Server not found. Please check your Kimai URL.")
            } else {
                callback(false, "Connection failed: " + xhr.status + " " + xhr.statusText)
            }
        }
    }
    
    xhr.onerror = function() {
        callback(false, "Network error. Please check your connection and URL.")
    }
    
    xhr.send()
}

/**
 * Load projects from Kimai
 * @param {string} kimaiUrl - The Kimai server URL
 * @param {string} apiToken - The API token
 * @param {function} callback - Callback function (projects: array or null)
 */
function loadProjects(kimaiUrl, apiToken, callback) {
    if (!kimaiUrl || !apiToken) {
        callback(null)
        return
    }

    var xhr = createAuthenticatedRequest("GET", kimaiUrl, "/api/projects?visible=3&order=name&orderBy=ASC", apiToken, false)
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var projects = JSON.parse(xhr.responseText)
                    callback(projects)
                } catch (e) {
                    console.error("Failed to parse projects:", e)
                    callback(null)
                }
            } else {
                console.error("Failed to load projects:", xhr.status, xhr.statusText)
                callback(null)
            }
        }
    }
    
    xhr.send()
}

/**
 * Load activities for a specific project
 * @param {string} kimaiUrl - The Kimai server URL
 * @param {string} apiToken - The API token
 * @param {number} projectId - The project ID
 * @param {function} callback - Callback function (activities: array or null)
 */
function loadActivities(kimaiUrl, apiToken, projectId, callback) {
    if (!kimaiUrl || !apiToken) {
        callback(null)
        return
    }

    var xhr = createAuthenticatedRequest("GET", kimaiUrl, "/api/activities?project=" + projectId + "&visible=3&order=name&orderBy=ASC", apiToken, false)
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var activities = JSON.parse(xhr.responseText)
                    callback(activities)
                } catch (e) {
                    console.error("Failed to parse activities:", e)
                    callback(null)
                }
            } else {
                console.error("Failed to load activities:", xhr.status, xhr.statusText)
                callback(null)
            }
        }
    }
    
    xhr.send()
}

/**
 * Fetch active timesheet
 * @param {string} kimaiUrl - The Kimai server URL
 * @param {string} apiToken - The API token
 * @param {function} callback - Callback function (timesheets: array or null)
 */
function fetchActiveTimesheet(kimaiUrl, apiToken, callback) {
    if (!kimaiUrl || !apiToken) {
        callback(null)
        return
    }

    var xhr = createAuthenticatedRequest("GET", kimaiUrl, "/api/timesheets/active", apiToken, false)
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var timesheets = JSON.parse(xhr.responseText)
                    callback(timesheets)
                } catch (e) {
                    console.error("Failed to parse active timesheet:", e)
                    callback(null)
                }
            } else {
                callback(null)
            }
        }
    }
    
    xhr.send()
}

/**
 * Start tracking time for a project and activity
 * @param {string} kimaiUrl - The Kimai server URL
 * @param {string} apiToken - The API token
 * @param {number} projectId - The project ID
 * @param {number} activityId - The activity ID
 * @param {function} callback - Callback function (success: boolean, response: object or null)
 */
function startTracking(kimaiUrl, apiToken, projectId, activityId, callback) {
    if (!kimaiUrl || !apiToken) {
        callback(false, null)
        return
    }

    var xhr = createAuthenticatedRequest("POST", kimaiUrl, "/api/timesheets", apiToken, true)
    
    var data = {
        begin: new Date().toISOString(),
        project: projectId,
        activity: activityId
    }
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200 || xhr.status === 201) {
                try {
                    var response = JSON.parse(xhr.responseText)
                    callback(true, response)
                } catch (e) {
                    console.error("Failed to parse start tracking response:", e)
                    callback(false, null)
                }
            } else {
                console.error("Failed to start tracking:", xhr.status, xhr.statusText)
                callback(false, null)
            }
        }
    }
    
    xhr.send(JSON.stringify(data))
}

/**
 * Stop tracking time for a timesheet
 * @param {string} kimaiUrl - The Kimai server URL
 * @param {string} apiToken - The API token
 * @param {number} timesheetId - The timesheet ID
 * @param {function} callback - Callback function (success: boolean)
 */
function stopTracking(kimaiUrl, apiToken, timesheetId, callback) {
    if (!kimaiUrl || !apiToken) {
        callback(false)
        return
    }

    var xhr = createAuthenticatedRequest("PATCH", kimaiUrl, "/api/timesheets/" + timesheetId + "/stop", apiToken, true)
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                callback(true)
            } else {
                console.error("Failed to stop tracking:", xhr.status, xhr.statusText)
                callback(false)
            }
        }
    }
    
    xhr.send()
}
