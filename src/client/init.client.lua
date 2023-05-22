local knit = require(game:GetService("ReplicatedStorage").Packages.knit)

knit.AddControllers(script.Controllers)

knit.Start():andThen(function()
    print("Client initialized!")
end):catch(warn)
