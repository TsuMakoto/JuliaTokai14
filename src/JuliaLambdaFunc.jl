module JuliaLambdaFunc

using JSON

function lambda_handler(body, headers)
    body = JSON.json(Dict("message" => "Hello, world!"))
    headers = Dict("Content-Type" => "application/json")
    return JSON.json(Dict("statusCode" => 200, "headers" => headers, "body" => body))
end

end
