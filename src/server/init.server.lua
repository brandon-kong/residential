local knit = require(game:GetService("ReplicatedStorage").Packages.knit)

knit.AddServices(script.Services)

knit.Start():andThen(function()
    print("Server initialized!")
end):catch(warn)