--!strict

local API = {}
API.__index = API

export type Result<T, E> = {
	_ok: boolean,
	_value: T?,
	_error: E?,
}

function API.Ok<T, E>(value: T): Result<T, E>
	return setmetatable({ _ok = true, _value = value, _error = nil }, API) :: any
end

function API.Err<T, E>(err: E): Result<T, E>
	return setmetatable({ _ok = false, _value = nil, _error = err }, API) :: any
end

function API.IsOk<T, E>(self: Result<T, E>): boolean
	return self._ok
end

function API.IsErr<T, E>(self: Result<T, E>): boolean
	return not self._ok
end

function API.Unwrap<T, E>(self: Result<T, E>): T
	if not self._ok then
		error(`Result:Unwrap() chamado em um Err: {tostring(self._error)}`, 2)
	end
	return self._value :: T
end

function API.UnwrapOr<T, E>(self: Result<T, E>, default: T): T
	if self._ok then
		return self._value :: T
	end
	return default
end

function API.UnwrapErr<T, E>(self: Result<T, E>): E
	if self._ok then
		error("Result:UnwrapErr() chamado em um Ok", 2)
	end
	return self._error :: E
end

function API.Map<T, E, U>(self: Result<T, E>, mapper: (T) -> U): Result<U, E>
	if self._ok then
		return API.Ok((mapper(self._value :: T)))
	end
	return API.Err(self._error :: E)
end

function API.AndThen<T, E, U>(self: Result<T, E>, next: (T) -> Result<U, E>): Result<U, E>
	if self._ok then
		return next(self._value :: T)
	end
	return API.Err(self._error :: E)
end

function API.Match<T, E, R>(self: Result<T, E>, onOk: (T) -> R, onErr: (E) -> R): R
	if self._ok then
		return onOk(self._value :: T)
	end
	return onErr(self._error :: E)
end

return API
