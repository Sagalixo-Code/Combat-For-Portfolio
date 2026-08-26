local API = script:WaitForChild("API")

return require("./Syntax/__index/From").import(API) :: {
	Class: typeof(require(API.Class)),
	Enum: typeof(require(API.Enum)),
	Option: typeof(require(API.Option)),
	Result: typeof(require(API.Result)),
	Struct: typeof(require(API.Struct)),
	Interface: typeof(require(API.Interface)),
}
