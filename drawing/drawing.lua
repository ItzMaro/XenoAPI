local coreGui = game:GetService("CoreGui")

local camera = workspace.CurrentCamera
local drawingUI = Instance.new("ScreenGui")
drawingUI.Name = "Drawing | Xeno"
drawingUI.IgnoreGuiInset = true
drawingUI.DisplayOrder = 0x7fffffff
drawingUI.Parent = coreGui

local drawingIndex = 0
local drawingFontsEnum = {
	[0] = Font.fromEnum(Enum.Font.Roboto),
	[1] = Font.fromEnum(Enum.Font.Legacy),
	[2] = Font.fromEnum(Enum.Font.SourceSans),
	[3] = Font.fromEnum(Enum.Font.RobotoMono)
}

local function getFontFromIndex(fontIndex)
	return drawingFontsEnum[fontIndex]
end

local function convertTransparency(transparency)
	return math.clamp(1 - transparency, 0, 1)
end

local baseDrawingObj = setmetatable({
	Visible = true,
	ZIndex = 0,
	Transparency = 1,
	Color = Color3.new(),
	Remove = function(self)
		setmetatable(self, nil)
	end,
	Destroy = function(self)
		setmetatable(self, nil)
	end,
	SetProperty = function(self, index, value)
		if self[index] ~= nil then
			self[index] = value
		else
			warn("Attempted to set invalid property: " .. tostring(index))
		end
	end,
	GetProperty = function(self, index)
		if self[index] ~= nil then
			return self[index]
		else
			warn("Attempted to get invalid property: " .. tostring(index))
			return nil
		end
	end,
	SetParent = function(self, parent)
		self.Parent = parent
	end
}, {
	__add = function(t1, t2)
		local result = {}
		for index, value in pairs(t1) do
			result[index] = value
		end
		for index, value in pairs(t2) do
			result[index] = value
		end
		return result
	end
})

local DrawingLib = {}
DrawingLib.Fonts = {
	["UI"] = 0,
	["System"] = 1,
	["Plex"] = 2,
	["Monospace"] = 3
}

function DrawingLib.new(drawingType)
	drawingIndex += 1
	if drawingType == "Line" then
		return DrawingLib.createLine()
	elseif drawingType == "Text" then
		return DrawingLib.createText()
	elseif drawingType == "Circle" then
		return DrawingLib.createCircle()
	elseif drawingType == "Square" then
		return DrawingLib.createSquare()
	elseif drawingType == "Image" then
		return DrawingLib.createImage()
	elseif drawingType == "Quad" then
		return DrawingLib.createQuad()
	elseif drawingType == "Triangle" then
		return DrawingLib.createTriangle()
	elseif drawingType == "Frame" then
		return DrawingLib.createFrame()
	elseif drawingType == "ScreenGui" then
		return DrawingLib.createScreenGui()
	elseif drawingType == "TextButton" then
		return DrawingLib.createTextButton()
	elseif drawingType == "TextLabel" then
		return DrawingLib.createTextLabel()
	elseif drawingType == "TextBox" then
		return DrawingLib.createTextBox()
	else
		error("Invalid drawing type: " .. tostring(drawingType))
	end
end

function DrawingLib.createLine()
	local lineObj = ({
		From = Vector2.zero,
		To = Vector2.zero,
		Thickness = 1
	} + baseDrawingObj)

	local lineFrame = Instance.new("Frame")
	lineFrame.Name = drawingIndex
	lineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	lineFrame.BorderSizePixel = 0

	lineFrame.Parent = drawingUI
	return setmetatable({Parent = drawingUI}, {
		__newindex = function(_, index, value)
			if lineObj[index] == nil then 
				warn("Invalid property: " .. tostring(index))
				return 
			end

			if index == "From" or index == "To" then
				local direction = (index == "From" and lineObj.To or value) - (index == "From" and value or lineObj.From)
				local center = (lineObj.To + lineObj.From) / 2
				local distance = direction.Magnitude
				local theta = math.deg(math.atan2(direction.Y, direction.X))

				lineFrame.Position = UDim2.fromOffset(center.X, center.Y)
				lineFrame.Rotation = theta
				lineFrame.Size = UDim2.fromOffset(distance, lineObj.Thickness)
			elseif index == "Thickness" then
				lineFrame.Size = UDim2.fromOffset((lineObj.To - lineObj.From).Magnitude, value)
			elseif index == "Visible" then
				lineFrame.Visible = value
			elseif index == "ZIndex" then
				lineFrame.ZIndex = value
			elseif index == "Transparency" then
				lineFrame.BackgroundTransparency = convertTransparency(value)
			elseif index == "Color" then
				lineFrame.BackgroundColor3 = value
			elseif index == "Parent" then
				lineFrame.Parent = value
			end
			lineObj[index] = value
		end,
		__index = function(self, index)
			if index == "Remove" or index == "Destroy" then
				return function()
					lineFrame:Destroy()
					lineObj:Remove()
				end
			end
			return lineObj[index]
		end,
		__tostring = function() return "Drawing" end
	})
end

function DrawingLib.createText()
	local textObj = ({
		Text = "",
		Font = DrawingLib.Fonts.UI,
		Size = 0,
		Position = Vector2.zero,
		Center = false,
		Outline = false,
		OutlineColor = Color3.new()
	} + baseDrawingObj)

	local textLabel, uiStroke = Instance.new("TextLabel"), Instance.new("UIStroke")
	textLabel.Name = drawingIndex
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.BorderSizePixel = 0
	textLabel.BackgroundTransparency = 1

	local function updateTextPosition()
		local textBounds = textLabel.TextBounds
		local offset = textBounds / 2
		textLabel.Size = UDim2.fromOffset(textBounds.X, textBounds.Y)
		textLabel.Position = UDim2.fromOffset(textObj.Position.X + (not textObj.Center and offset.X or 0), textObj.Position.Y + offset.Y)
	end

	textLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateTextPosition)

	uiStroke.Thickness = 1
	uiStroke.Enabled = textObj.Outline
	uiStroke.Color = textObj.Color

	textLabel.Parent, uiStroke.Parent = drawingUI, textLabel

	return setmetatable({Parent = drawingUI}, {
		__newindex = function(_, index, value)
			if textObj[index] == nil then 
				warn("Invalid property: " .. tostring(index))
				return 
			end

			if index == "Text" then
				textLabel.Text = value
			elseif index == "Font" then
				textLabel.FontFace = getFontFromIndex(math.clamp(value, 0, 3))
			elseif index == "Size" then
				textLabel.TextSize = value
			elseif index == "Position" then
				updateTextPosition()
			elseif index == "Center" then
				textLabel.Position = UDim2.fromOffset((value and camera.ViewportSize / 2 or textObj.Position).X, textObj.Position.Y)
			elseif index == "Outline" then
				uiStroke.Enabled = value
			elseif index == "OutlineColor" then
				uiStroke.Color = value
			elseif index == "Visible" then
				textLabel.Visible = value
			elseif index == "ZIndex" then
				textLabel.ZIndex = value
			elseif index == "Transparency" then
				local transparency = convertTransparency(value)
				textLabel.TextTransparency = transparency
				uiStroke.Transparency = transparency
			elseif index == "Color" then
				textLabel.TextColor3 = value
			elseif index == "Parent" then
				textLabel.Parent = value
			end
			textObj[index] = value
		end,
		__index = function(self, index)
			if index == "Remove" or index == "Destroy" then
				return function()
					textLabel:Destroy()
					textObj:Remove()
				end
			elseif index == "TextBounds" then
				return textLabel.TextBounds
			end
			return textObj[index]
		end,
		__tostring = function() return "Drawing" end
	})
end

function DrawingLib.createCircle()
	local circleObj = ({
		Radius = 150,
		Position = Vector2.zero,
		Thickness = 0.7,
		Filled = false
	} + baseDrawingObj)

	local circleFrame, uiCorner, uiStroke = Instance.new("Frame"), Instance.new("UICorner"), Instance.new("UIStroke")
	circleFrame.Name = drawingIndex
	circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	circleFrame.BorderSizePixel = 0

	uiCorner.CornerRadius = UDim.new(1, 0)
	circleFrame.Size = UDim2.fromOffset(circleObj.Radius, circleObj.Radius)
	uiStroke.Thickness = circleObj.Thickness
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	circleFrame.Parent, uiCorner.Parent, uiStroke.Parent = drawingUI, circleFrame, circleFrame

	return setmetatable({Parent = drawingUI}, {
		__newindex = function(_, index, value)
			if circleObj[index] == nil then 
				warn("Invalid property: " .. tostring(index))
				return 
			end

			if index == "Radius" then
				local radius = value * 2
				circleFrame.Size = UDim2.fromOffset(radius, radius)
			elseif index == "Position" then
				circleFrame.Position = UDim2.fromOffset(value.X, value.Y)
			elseif index == "Thickness" then
				uiStroke.Thickness = math.clamp(value, 0.6, 0x7fffffff)
			elseif index == "Filled" then
				circleFrame.BackgroundTransparency = value and convertTransparency(circleObj.Transparency) or 1
				uiStroke.Enabled = not value
			elseif index == "Visible" then
				circleFrame.Visible = value
			elseif index == "ZIndex" then
				circleFrame.ZIndex = value
			elseif index == "Transparency" then
				local transparency = convertTransparency(value)
				circleFrame.BackgroundTransparency = circleObj.Filled and transparency or 1
				uiStroke.Transparency = transparency
			elseif index == "Color" then
				circleFrame.BackgroundColor3 = value
				uiStroke.Color = value
			elseif index == "Parent" then
				circleFrame.Parent = value
			end
			circleObj[index] = value
		end,
		__index = function(self, index)
			if index == "Remove" or index == "Destroy" then
				return function()
					circleFrame:Destroy()
					circleObj:Remove()
				end
			end
			return circleObj[index]
		end,
		__tostring = function() return "Drawing" end
	})
end

function DrawingLib.createSquare()
	local squareObj = ({
		Size = Vector2.zero,
		Position = Vector2.zero,
		Thickness = 0.7,
		Filled = false
	} + baseDrawingObj)

	local squareFrame, uiStroke = Instance.new("Frame"), Instance.new("UIStroke")
	squareFrame.Name = drawingIndex
	squareFrame.BorderSizePixel = 0

	squareFrame.Parent, uiStroke.Parent = drawingUI, squareFrame

	return setmetatable({Parent = drawingUI}, {
		__newindex = function(_, index, value)
			if squareObj[index] == nil then 
				warn("Invalid property: " .. tostring(index))
				return 
			end

			if index == "Size" then
				squareFrame.Size = UDim2.fromOffset(value.X, value.Y)
			elseif index == "Position" then
				squareFrame.Position = UDim2.fromOffset(value.X, value.Y)
			elseif index == "Thickness" then
				uiStroke.Thickness = math.clamp(value, 0.6, 0x7fffffff)
			elseif index == "Filled" then
				squareFrame.BackgroundTransparency = value and convertTransparency(squareObj.Transparency) or 1
				uiStroke.Enabled = not value
			elseif index == "Visible" then
				squareFrame.Visible = value
			elseif index == "ZIndex" then
				squareFrame.ZIndex = value
			elseif index == "Transparency" then
				local transparency = convertTransparency(value)
				squareFrame.BackgroundTransparency = squareObj.Filled and transparency or 1
				uiStroke.Transparency = transparency
			elseif index == "Color" then
				squareFrame.BackgroundColor3 = value
				uiStroke.Color = value
			elseif index == "Parent" then
				squareFrame.Parent = value
			end
			squareObj[index] = value
		end,
		__index = function(self, index)
			if index == "Remove" or index == "Destroy" then
				return function()
					squareFrame:Destroy()
					squareObj:Remove()
				end
			end
			return squareObj[index]
		end,
		__tostring = function() return "Drawing" end
	})
end

function DrawingLib.createImage()
	local imageObj = ({
		Data = "",
		DataURL = "rbxassetid://0",
		Size = Vector2.zero,
		Position = Vector2.zero
	} + baseDrawingObj)

	local imageFrame = Instance.new("ImageLabel")
	imageFrame.Name = drawingIndex
	imageFrame.BorderSizePixel = 0
	imageFrame.ScaleType = Enum.ScaleType.Stretch
	imageFrame.BackgroundTransparency = 1

	imageFrame.Parent = drawingUI

	return setmetatable({Parent = drawingUI}, {
		__newindex = function(_, index, value)
			if imageObj[index] == nil then 
				warn("Invalid property: " .. tostring(index))
				return 
			end

			if index == "Data" then
			elseif index == "DataURL" then
				imageFrame.Image = value
			elseif index == "Size" then
				imageFrame.Size = UDim2.fromOffset(value.X, value.Y)
			elseif index == "Position" then
				imageFrame.Position = UDim2.fromOffset(value.X, value.Y)
			elseif index == "Visible" then
				imageFrame.Visible = value
			elseif index == "ZIndex" then
				imageFrame.ZIndex = value
			elseif index == "Transparency" then
				imageFrame.ImageTransparency = convertTransparency(value)
			elseif index == "Color" then
				imageFrame.ImageColor3 = value
			elseif index == "Parent" then
				imageFrame.Parent = value
			end
			imageObj[index] = value
		end,
		__index = function(self, index)
			if index == "Remove" or index == "Destroy" then
				return function()
					imageFrame:Destroy()
					imageObj:Remove()
				end
			elseif index == "Data" then
				return nil 
			end
			return imageObj[index]
		end,
		__tostring = function() return "Drawing" end
	})
end

function DrawingLib.createQuad()
	local quadObj = ({
		PointA = Vector2.zero,
		PointB = Vector2.zero,
		PointC = Vector2.zero,
		PointD = Vector2.zero,
		Thickness = 1,
		Filled = false
	} + baseDrawingObj)

	local _linePoints = {
		A = DrawingLib.createLine(),
		B = DrawingLib.createLine(),
		C = DrawingLib.createLine(),
		D = DrawingLib.createLine()
	}

	local fillFrame = Instance.new("Frame")
	fillFrame.Name = drawingIndex .. "_Fill"
	fillFrame.BorderSizePixel = 0
	fillFrame.BackgroundTransparency = quadObj.Transparency
	fillFrame.BackgroundColor3 = quadObj.Color
	fillFrame.ZIndex = quadObj.ZIndex
	fillFrame.Visible = quadObj.Visible and quadObj.Filled

	fillFrame.Parent = drawingUI

	return setmetatable({Parent = drawingUI}, {
		__newindex = function(_, index, value)
			if quadObj[index] == nil then 
				warn("Invalid property: " .. tostring(index))
				return 
			end

			if index == "PointA" then
				_linePoints.A.From = value
				_linePoints.B.To = value
			elseif index == "PointB" then
				_linePoints.B.From = value
				_linePoints.C.To = value
			elseif index == "PointC" then
				_linePoints.C.From = value
				_linePoints.D.To = value
			elseif index == "PointD" then
				_linePoints.D.From = value
				_linePoints.A.To = value
			elseif index == "Thickness" or index == "Visible" or index == "Color" or index == "ZIndex" then
				for _, linePoint in pairs(_linePoints) do
					linePoint[index] = value
				end
				if index == "Visible" then
					fillFrame.Visible = value and quadObj.Filled
				elseif index == "Color" then
					fillFrame.BackgroundColor3 = value
				elseif index == "ZIndex" then
					fillFrame.ZIndex = value
				end
			elseif index == "Filled" then
				for _, linePoint in pairs(_linePoints) do
					linePoint.Transparency = value and 1 or quadObj.Transparency
				end
				fillFrame.Visible = value
			elseif index == "Parent" then
				fillFrame.Parent = value
			end
			quadObj[index] = value
		end,
		__index = function(self, index)
			if index == "Remove" or index == "Destroy" then
				return function()
					for _, linePoint in pairs(_linePoints) do
						linePoint:Remove()
					end
					fillFrame:Destroy()
					quadObj:Remove()
				end
			end
			return quadObj[index]
		end,
		__tostring = function() return "Drawing" end
	})
end

function DrawingLib.createTriangle()
	local triangleObj = ({
		PointA = Vector2.zero,
		PointB = Vector2.zero,
		PointC = Vector2.zero,
		Thickness = 1,
		Filled = false
	} + baseDrawingObj)

	local _linePoints = {
		A = DrawingLib.createLine(),
		B = DrawingLib.createLine(),
		C = DrawingLib.createLine()
	}

	local fillFrame = Instance.new("Frame")
	fillFrame.Name = drawingIndex .. "_Fill"
	fillFrame.BorderSizePixel = 0
	fillFrame.BackgroundTransparency = triangleObj.Transparency
	fillFrame.BackgroundColor3 = triangleObj.Color
	fillFrame.ZIndex = triangleObj.ZIndex
	fillFrame.Visible = triangleObj.Visible and triangleObj.Filled

	fillFrame.Parent = drawingUI

	return setmetatable({Parent = drawingUI}, {
		__newindex = function(_, index, value)
			if triangleObj[index] == nil then 
				warn("Invalid property: " .. tostring(index))
				return 
			end

			if index == "PointA" then
				_linePoints.A.From = value
				_linePoints.B.To = value
			elseif index == "PointB" then
				_linePoints.B.From = value
				_linePoints.C.To = value
			elseif index == "PointC" then
				_linePoints.C.From = value
				_linePoints.A.To = value
			elseif index == "Thickness" or index == "Visible" or index == "Color" or index == "ZIndex" then
				for _, linePoint in pairs(_linePoints) do
					linePoint[index] = value
				end
				if index == "Visible" then
					fillFrame.Visible = value and triangleObj.Filled
				elseif index == "Color" then
					fillFrame.BackgroundColor3 = value
				elseif index == "ZIndex" then
					fillFrame.ZIndex = value
				end
			elseif index == "Filled" then
				for _, linePoint in pairs(_linePoints) do
					linePoint.Transparency = value and 1 or triangleObj.Transparency
				end
				fillFrame.Visible = value
			elseif index == "Parent" then
				fillFrame.Parent = value
			end
			triangleObj[index] = value
		end,
		__index = function(self, index)
			if index == "Remove" or index == "Destroy" then
				return function()
					for _, linePoint in pairs(_linePoints) do
						linePoint:Remove()
					end
					fillFrame:Destroy()
					triangleObj:Remove()
				end
			end
			return triangleObj[index]
		end,
		__tostring = function() return "Drawing" end
	})
end

function DrawingLib.createFrame()
	local frameObj = ({
		Size = UDim2.new(0, 100, 0, 100),
		Position = UDim2.new(0, 0, 0, 0),
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
		Visible = true,
		ZIndex = 1
	} + baseDrawingObj)

	local frame = Instance.new("Frame")
	frame.Name = drawingIndex
	frame.Size = frameObj.Size
	frame.Position = frameObj.Position
	frame.BackgroundColor3 = frameObj.Color
	frame.BackgroundTransparency = convertTransparency(frameObj.Transparency)
	frame.Visible = frameObj.Visible
	frame.ZIndex = frameObj.ZIndex
	frame.BorderSizePixel = 0

	frame.Parent = drawingUI

	return setmetatable({Parent = drawingUI}, {
		__newindex = function(_, index, value)
			if frameObj[index] == nil then
				warn("Invalid property: " .. tostring(index))
				return
			end

			if index == "Size" then
				frame.Size = value
			elseif index == "Position" then
				frame.Position = value
			elseif index == "Color" then
				frame.BackgroundColor3 = value
			elseif index == "Transparency" then
				frame.BackgroundTransparency = convertTransparency(value)
			elseif index == "Visible" then
				frame.Visible = value
			elseif index == "ZIndex" then
				frame.ZIndex = value
			elseif index == "Parent" then
				frame.Parent = value
			end
			frameObj[index] = value
		end,
		__index = function(self, index)
			if index == "Remove" or index == "Destroy" then
				return function()
					frame:Destroy()
					frameObj:Remove()
				end
			end
			return frameObj[index]
		end,
		__tostring = function() return "Drawing" end
	})
end

task.spawn(function()
    wait(3)
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local headshotUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"

    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "[Zenora]",
        Text = "Injected! 😀",
        Duration = 20,
        Icon = headshotUrl  -- Set the player's headshot as the icon
    })

    print("[-] Injected Zenora Freemium to Roblox\nhttps://discord.gg/exploitnews")
	-- Gui to Lua
-- Version: 3.2

-- Instances:

local ZenoraNotification = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TextLabel = Instance.new("TextLabel")
local TextLabel_2 = Instance.new("TextLabel")
local Frame_2 = Instance.new("Frame")
local UICorner_2 = Instance.new("UICorner")
local ImageLabel = Instance.new("ImageLabel")
local UICorner_3 = Instance.new("UICorner")

--Properties:

ZenoraNotification.Name = "ZenoraNotification"
ZenoraNotification.Parent = game.CoreGui
ZenoraNotification.ResetOnSpawn = false

Frame.Parent = ZenoraNotification
Frame.AnchorPoint = Vector2.new(0.5, 0)
Frame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(1.00903153, -125, 0.836156189, 0)
Frame.Size = UDim2.new(0, 209, 0, 92)

UICorner.CornerRadius = UDim.new(0, 5)
UICorner.Parent = Frame

TextLabel.Parent = Frame
TextLabel.BackgroundTransparency = 1.000
TextLabel.Position = UDim2.new(0.195430487, 0, 0.0565218702, 0)
TextLabel.Size = UDim2.new(0, 126, 0, 27)
TextLabel.Font = Enum.Font.GothamBold
TextLabel.Text = "Zenora Freemium"
TextLabel.TextColor3 = Color3.fromRGB(207, 207, 207)
TextLabel.TextScaled = true
TextLabel.TextSize = 16.000
TextLabel.TextWrapped = true
TextLabel.TextXAlignment = Enum.TextXAlignment.Left

TextLabel_2.Parent = Frame
TextLabel_2.BackgroundTransparency = 1.000
TextLabel_2.Position = UDim2.new(0.0660289451, 0, 0.619565189, 0)
TextLabel_2.Size = UDim2.new(0, 181, 0, 20)
TextLabel_2.Font = Enum.Font.Gotham
TextLabel_2.Text = "Zenora has Injected!"
TextLabel_2.TextColor3 = Color3.fromRGB(207, 207, 207)
TextLabel_2.TextScaled = true
TextLabel_2.TextSize = 14.000
TextLabel_2.TextWrapped = true
TextLabel_2.TextXAlignment = Enum.TextXAlignment.Left

Frame_2.Parent = Frame
Frame_2.BackgroundColor3 = Color3.fromRGB(46, 46, 45)
Frame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame_2.BorderSizePixel = 0
Frame_2.Position = UDim2.new(0.0334928222, 0, 0.434782594, 0)
Frame_2.Size = UDim2.new(0, 194, 0, 4)

UICorner_2.CornerRadius = UDim.new(0, 10)
UICorner_2.Parent = Frame_2

ImageLabel.Parent = Frame
ImageLabel.BackgroundTransparency = 1.000
ImageLabel.Position = UDim2.new(0.0309999995, 0, 0.0500000007, 0)
ImageLabel.Size = UDim2.new(0, 30, 0, 30)
ImageLabel.Image = "rbxassetid://115286258189692"

UICorner_3.CornerRadius = UDim.new(0, 15)
UICorner_3.Parent = ImageLabel

-- Scripts:

local function VGLUW_fake_script() -- Frame.LocalScript 
	local script = Instance.new('LocalScript', Frame)

	local tweenService = game:GetService("TweenService")
	local frame = script.Parent
	local gui = ZenoraNotification
	
	local tweenInfo = TweenInfo.new(
		0.5, -- Time
		Enum.EasingStyle.Quad, -- Easing style
		Enum.EasingDirection.Out, -- Easing direction
		0, -- No repeat
		false, -- No reverse
		0 -- No delay
	)
	
	local tween = tweenService:Create(frame, tweenInfo, {BackgroundTransparency = 0})
	tween:Play()
	
	-- Optional: Auto-remove after 5 seconds with smooth disappearance
	wait(10)
	local fadeOut = tweenService:Create(frame, tweenInfo, {BackgroundTransparency = 1})
	fadeOut:Play()
	fadeOut.Completed:Connect(function()
		gui:Destroy()
	end)
	
end
coroutine.wrap(VGLUW_fake_script)()
-- Gui to Lua
-- Version: 3.2

-- Instances:

local InternalGUI = Instance.new("ScreenGui")
local Topbar = Instance.new("Frame")
local Main = Instance.new("Frame")
local Tabs = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")
local File = Instance.new("Frame")
local File_2 = Instance.new("TextButton")
local Dropdown = Instance.new("Frame")
local UIListLayout_2 = Instance.new("UIListLayout")
local Inject = Instance.new("TextButton")
local KillRoblox = Instance.new("TextButton")
local Credits = Instance.new("Frame")
local Credits_2 = Instance.new("TextButton")
local Games = Instance.new("Frame")
local Games_2 = Instance.new("TextButton")
local HotScripts = Instance.new("Frame")
local HotScripts_2 = Instance.new("TextButton")
local Dropdown_2 = Instance.new("Frame")
local UIListLayout_3 = Instance.new("UIListLayout")
local DarkDex = Instance.new("TextButton")
local OpenGui = Instance.new("TextButton")
local RemoteSpy = Instance.new("TextButton")
local GameSense = Instance.new("TextButton")
local UnnamedESP = Instance.new("TextButton")
local InfiniteYield = Instance.new("TextButton")
local CMDX = Instance.new("TextButton")
local space = Instance.new("Frame")
local Others = Instance.new("Frame")
local Others_2 = Instance.new("TextButton")
local Dropdown_3 = Instance.new("Frame")
local UIListLayout_4 = Instance.new("UIListLayout")
local GetKey = Instance.new("TextButton")
local Discord = Instance.new("TextButton")
local BlueLine = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ScriptsBox = Instance.new("ScrollingFrame")
local UIListLayout_5 = Instance.new("UIListLayout")
local Example = Instance.new("TextButton")
local Execute = Instance.new("TextButton")
local Clear = Instance.new("TextButton")
local OpenFile = Instance.new("TextButton")
local SaveFile = Instance.new("TextButton")
local Inject_2 = Instance.new("TextButton")
local Options = Instance.new("TextButton")
local Editor = Instance.new("Frame")
local Line = Instance.new("Frame")
local EditorScroll = Instance.new("ScrollingFrame")
local Editor_2 = Instance.new("TextBox")
local NumberScroll = Instance.new("ScrollingFrame")
local Numbers = Instance.new("TextLabel")
local Logo = Instance.new("ImageLabel")
local Close = Instance.new("ImageButton")
local Minimize = Instance.new("ImageButton")
local ScriptTabs = Instance.new("Frame")
local UIListLayout_6 = Instance.new("UIListLayout")
local Example1 = Instance.new("Frame")
local Close_2 = Instance.new("TextButton")
local Selecter = Instance.new("TextButton")
local NewTab = Instance.new("ImageButton")
local Fill = Instance.new("Frame")
local Open = Instance.new("ImageButton")
local UICorner = Instance.new("UICorner")

--Properties:

InternalGUI.Name = "InternalGUI"
InternalGUI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

Topbar.Name = "Topbar"
Topbar.Parent = InternalGUI
Topbar.Active = true
Topbar.AnchorPoint = Vector2.new(0.5, 0)
Topbar.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Topbar.BorderSizePixel = 0
Topbar.Position = UDim2.new(0.5, 0, 0.300000012, 0)
Topbar.Size = UDim2.new(0, 690, 0, 33)

Main.Name = "Main"
Main.Parent = Topbar
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Main.BorderSizePixel = 0
Main.Size = UDim2.new(0, 690, 0, 350)
Main.ZIndex = 0

Tabs.Name = "Tabs"
Tabs.Parent = Topbar
Tabs.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
Tabs.BorderSizePixel = 0
Tabs.Position = UDim2.new(0, 0, 1, 0)
Tabs.Size = UDim2.new(0, 690, 0, 24)

UIListLayout.Parent = Tabs
UIListLayout.FillDirection = Enum.FillDirection.Horizontal
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

File.Name = "File"
File.Parent = Tabs
File.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
File.BackgroundTransparency = 1.000
File.LayoutOrder = 1
File.Size = UDim2.new(0, 41, 0, 24)
File.ZIndex = 2

File_2.Name = "File"
File_2.Parent = File
File_2.AnchorPoint = Vector2.new(0.5, 0.5)
File_2.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
File_2.BackgroundTransparency = 1.000
File_2.BorderColor3 = Color3.fromRGB(0, 120, 215)
File_2.Position = UDim2.new(0.5, 0, 0.5, 0)
File_2.Size = UDim2.new(0, 35, 0, 18)
File_2.ZIndex = 2
File_2.AutoButtonColor = false
File_2.Font = Enum.Font.SourceSans
File_2.Text = "File"
File_2.TextColor3 = Color3.fromRGB(255, 255, 255)
File_2.TextSize = 15.000

Dropdown.Name = "Dropdown"
Dropdown.Parent = File_2
Dropdown.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
Dropdown.BorderColor3 = Color3.fromRGB(40, 40, 40)
Dropdown.BorderSizePixel = 0
Dropdown.Position = UDim2.new(0, 0, 1, 0)
Dropdown.Size = UDim2.new(0, 127, 0, 44)
Dropdown.Visible = false
Dropdown.ZIndex = 3

UIListLayout_2.Parent = Dropdown
UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder

Inject.Name = "Inject"
Inject.Parent = Dropdown
Inject.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
Inject.BackgroundTransparency = 1.000
Inject.BorderColor3 = Color3.fromRGB(0, 120, 215)
Inject.Position = UDim2.new(0.441379309, 0, 1.31818175, 0)
Inject.Size = UDim2.new(0, 127, 0, 22)
Inject.ZIndex = 4
Inject.AutoButtonColor = false
Inject.Font = Enum.Font.SourceSans
Inject.Text = "                  Inject"
Inject.TextColor3 = Color3.fromRGB(255, 255, 255)
Inject.TextSize = 14.000
Inject.TextXAlignment = Enum.TextXAlignment.Left

KillRoblox.Name = "KillRoblox"
KillRoblox.Parent = Dropdown
KillRoblox.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
KillRoblox.BackgroundTransparency = 1.000
KillRoblox.BorderColor3 = Color3.fromRGB(0, 120, 215)
KillRoblox.Position = UDim2.new(0.441379309, 0, 1.31818175, 0)
KillRoblox.Size = UDim2.new(0, 127, 0, 22)
KillRoblox.ZIndex = 4
KillRoblox.AutoButtonColor = false
KillRoblox.Font = Enum.Font.SourceSans
KillRoblox.Text = "                  Kill Roblox"
KillRoblox.TextColor3 = Color3.fromRGB(255, 255, 255)
KillRoblox.TextSize = 14.000
KillRoblox.TextXAlignment = Enum.TextXAlignment.Left

Credits.Name = "Credits"
Credits.Parent = Tabs
Credits.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Credits.BackgroundTransparency = 1.000
Credits.LayoutOrder = 2
Credits.Size = UDim2.new(0, 54, 0, 24)
Credits.ZIndex = 2

Credits_2.Name = "Credits"
Credits_2.Parent = Credits
Credits_2.AnchorPoint = Vector2.new(0.5, 0.5)
Credits_2.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
Credits_2.BackgroundTransparency = 1.000
Credits_2.BorderColor3 = Color3.fromRGB(0, 120, 215)
Credits_2.Position = UDim2.new(0.5, 0, 0.5, 0)
Credits_2.Size = UDim2.new(0, 54, 0, 18)
Credits_2.ZIndex = 2
Credits_2.AutoButtonColor = false
Credits_2.Font = Enum.Font.SourceSans
Credits_2.Text = "Credits"
Credits_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Credits_2.TextSize = 15.000

Games.Name = "Games"
Games.Parent = Tabs
Games.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Games.BackgroundTransparency = 1.000
Games.LayoutOrder = 3
Games.Size = UDim2.new(0, 56, 0, 24)
Games.ZIndex = 2

Games_2.Name = "Games"
Games_2.Parent = Games
Games_2.AnchorPoint = Vector2.new(0.5, 0.5)
Games_2.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
Games_2.BackgroundTransparency = 1.000
Games_2.BorderColor3 = Color3.fromRGB(0, 120, 215)
Games_2.Position = UDim2.new(0.5, 0, 0.5, 0)
Games_2.Size = UDim2.new(0, 53, 0, 18)
Games_2.ZIndex = 2
Games_2.AutoButtonColor = false
Games_2.Font = Enum.Font.SourceSans
Games_2.Text = "Games"
Games_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Games_2.TextSize = 15.000

HotScripts.Name = "HotScripts"
HotScripts.Parent = Tabs
HotScripts.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HotScripts.BackgroundTransparency = 1.000
HotScripts.LayoutOrder = 4
HotScripts.Size = UDim2.new(0, 82, 0, 24)
HotScripts.ZIndex = 2

HotScripts_2.Name = "HotScripts"
HotScripts_2.Parent = HotScripts
HotScripts_2.AnchorPoint = Vector2.new(0.5, 0.5)
HotScripts_2.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
HotScripts_2.BackgroundTransparency = 1.000
HotScripts_2.BorderColor3 = Color3.fromRGB(0, 120, 215)
HotScripts_2.Position = UDim2.new(0.5, 0, 0.5, 0)
HotScripts_2.Size = UDim2.new(0, 80, 0, 18)
HotScripts_2.ZIndex = 2
HotScripts_2.AutoButtonColor = false
HotScripts_2.Font = Enum.Font.SourceSans
HotScripts_2.Text = "Hot-Scripts"
HotScripts_2.TextColor3 = Color3.fromRGB(255, 255, 255)
HotScripts_2.TextSize = 15.000

Dropdown_2.Name = "Dropdown"
Dropdown_2.Parent = HotScripts_2
Dropdown_2.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
Dropdown_2.BorderColor3 = Color3.fromRGB(40, 40, 40)
Dropdown_2.BorderSizePixel = 0
Dropdown_2.Position = UDim2.new(0, 0, 1, 0)
Dropdown_2.Size = UDim2.new(0, 145, 0, 154)
Dropdown_2.Visible = false
Dropdown_2.ZIndex = 3

UIListLayout_3.Parent = Dropdown_2
UIListLayout_3.SortOrder = Enum.SortOrder.LayoutOrder

DarkDex.Name = "DarkDex"
DarkDex.Parent = Dropdown_2
DarkDex.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
DarkDex.BackgroundTransparency = 1.000
DarkDex.BorderColor3 = Color3.fromRGB(0, 120, 215)
DarkDex.Position = UDim2.new(0.441379309, 0, 1.31818175, 0)
DarkDex.Size = UDim2.new(0, 145, 0, 22)
DarkDex.ZIndex = 4
DarkDex.AutoButtonColor = false
DarkDex.Font = Enum.Font.SourceSans
DarkDex.Text = "                  DarkDex"
DarkDex.TextColor3 = Color3.fromRGB(255, 255, 255)
DarkDex.TextSize = 14.000
DarkDex.TextXAlignment = Enum.TextXAlignment.Left

OpenGui.Name = "OpenGui"
OpenGui.Parent = Dropdown_2
OpenGui.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
OpenGui.BackgroundTransparency = 1.000
OpenGui.BorderColor3 = Color3.fromRGB(0, 120, 215)
OpenGui.Position = UDim2.new(0.441379309, 0, 1.31818175, 0)
OpenGui.Size = UDim2.new(0, 145, 0, 22)
OpenGui.ZIndex = 4
OpenGui.AutoButtonColor = false
OpenGui.Font = Enum.Font.SourceSans
OpenGui.Text = "                  OpenGui"
OpenGui.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenGui.TextSize = 14.000
OpenGui.TextXAlignment = Enum.TextXAlignment.Left

RemoteSpy.Name = "RemoteSpy"
RemoteSpy.Parent = Dropdown_2
RemoteSpy.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
RemoteSpy.BackgroundTransparency = 1.000
RemoteSpy.BorderColor3 = Color3.fromRGB(0, 120, 215)
RemoteSpy.Position = UDim2.new(0.441379309, 0, 1.31818175, 0)
RemoteSpy.Size = UDim2.new(0, 145, 0, 22)
RemoteSpy.ZIndex = 4
RemoteSpy.AutoButtonColor = false
RemoteSpy.Font = Enum.Font.SourceSans
RemoteSpy.Text = "                  Remote Spy"
RemoteSpy.TextColor3 = Color3.fromRGB(255, 255, 255)
RemoteSpy.TextSize = 14.000
RemoteSpy.TextXAlignment = Enum.TextXAlignment.Left

GameSense.Name = "GameSense"
GameSense.Parent = Dropdown_2
GameSense.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
GameSense.BackgroundTransparency = 1.000
GameSense.BorderColor3 = Color3.fromRGB(0, 120, 215)
GameSense.Position = UDim2.new(0.441379309, 0, 1.31818175, 0)
GameSense.Size = UDim2.new(0, 145, 0, 22)
GameSense.ZIndex = 4
GameSense.AutoButtonColor = false
GameSense.Font = Enum.Font.SourceSans
GameSense.Text = "                  Game Sense"
GameSense.TextColor3 = Color3.fromRGB(255, 255, 255)
GameSense.TextSize = 14.000
GameSense.TextXAlignment = Enum.TextXAlignment.Left

UnnamedESP.Name = "UnnamedESP"
UnnamedESP.Parent = Dropdown_2
UnnamedESP.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
UnnamedESP.BackgroundTransparency = 1.000
UnnamedESP.BorderColor3 = Color3.fromRGB(0, 120, 215)
UnnamedESP.Position = UDim2.new(0.441379309, 0, 1.31818175, 0)
UnnamedESP.Size = UDim2.new(0, 145, 0, 22)
UnnamedESP.ZIndex = 4
UnnamedESP.AutoButtonColor = false
UnnamedESP.Font = Enum.Font.SourceSans
UnnamedESP.Text = "                  Unnamed ESP"
UnnamedESP.TextColor3 = Color3.fromRGB(255, 255, 255)
UnnamedESP.TextSize = 14.000
UnnamedESP.TextXAlignment = Enum.TextXAlignment.Left

InfiniteYield.Name = "InfiniteYield"
InfiniteYield.Parent = Dropdown_2
InfiniteYield.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
InfiniteYield.BackgroundTransparency = 1.000
InfiniteYield.BorderColor3 = Color3.fromRGB(0, 120, 215)
InfiniteYield.Position = UDim2.new(0.441379309, 0, 1.31818175, 0)
InfiniteYield.Size = UDim2.new(0, 145, 0, 22)
InfiniteYield.ZIndex = 4
InfiniteYield.AutoButtonColor = false
InfiniteYield.Font = Enum.Font.SourceSans
InfiniteYield.Text = "                  Infinite Yield"
InfiniteYield.TextColor3 = Color3.fromRGB(255, 255, 255)
InfiniteYield.TextSize = 14.000
InfiniteYield.TextXAlignment = Enum.TextXAlignment.Left

CMDX.Name = "CMDX"
CMDX.Parent = Dropdown_2
CMDX.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
CMDX.BackgroundTransparency = 1.000
CMDX.BorderColor3 = Color3.fromRGB(0, 120, 215)
CMDX.Position = UDim2.new(0.441379309, 0, 1.31818175, 0)
CMDX.Size = UDim2.new(0, 145, 0, 22)
CMDX.ZIndex = 4
CMDX.AutoButtonColor = false
CMDX.Font = Enum.Font.SourceSans
CMDX.Text = "                  CMD-X"
CMDX.TextColor3 = Color3.fromRGB(255, 255, 255)
CMDX.TextSize = 14.000
CMDX.TextXAlignment = Enum.TextXAlignment.Left

space.Name = "space"
space.Parent = Tabs
space.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
space.BorderSizePixel = 0
space.Size = UDim2.new(0, 3, 0, 24)
space.ZIndex = 2

Others.Name = "Others"
Others.Parent = Tabs
Others.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Others.BackgroundTransparency = 1.000
Others.LayoutOrder = 5
Others.Size = UDim2.new(0, 50, 0, 24)
Others.ZIndex = 2

Others_2.Name = "Others"
Others_2.Parent = Others
Others_2.AnchorPoint = Vector2.new(0.5, 0.5)
Others_2.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
Others_2.BackgroundTransparency = 1.000
Others_2.BorderColor3 = Color3.fromRGB(0, 120, 215)
Others_2.Position = UDim2.new(0.5, 0, 0.5, 0)
Others_2.Size = UDim2.new(0, 48, 0, 18)
Others_2.ZIndex = 2
Others_2.AutoButtonColor = false
Others_2.Font = Enum.Font.SourceSans
Others_2.Text = "Others"
Others_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Others_2.TextSize = 15.000

Dropdown_3.Name = "Dropdown"
Dropdown_3.Parent = Others_2
Dropdown_3.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
Dropdown_3.BorderColor3 = Color3.fromRGB(40, 40, 40)
Dropdown_3.BorderSizePixel = 0
Dropdown_3.Position = UDim2.new(0, 0, 1, 0)
Dropdown_3.Size = UDim2.new(0, 170, 0, 44)
Dropdown_3.Visible = false
Dropdown_3.ZIndex = 3

UIListLayout_4.Parent = Dropdown_3
UIListLayout_4.SortOrder = Enum.SortOrder.LayoutOrder

GetKey.Name = "GetKey"
GetKey.Parent = Dropdown_3
GetKey.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
GetKey.BackgroundTransparency = 1.000
GetKey.BorderColor3 = Color3.fromRGB(0, 120, 215)
GetKey.Position = UDim2.new(0.441379309, 0, 1.31818175, 0)
GetKey.Size = UDim2.new(0, 170, 0, 22)
GetKey.ZIndex = 4
GetKey.AutoButtonColor = false
GetKey.Font = Enum.Font.SourceSans
GetKey.Text = "                  Get Key"
GetKey.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKey.TextSize = 14.000
GetKey.TextXAlignment = Enum.TextXAlignment.Left

Discord.Name = "Discord"
Discord.Parent = Dropdown_3
Discord.BackgroundColor3 = Color3.fromRGB(181, 215, 243)
Discord.BackgroundTransparency = 1.000
Discord.BorderColor3 = Color3.fromRGB(0, 120, 215)
Discord.Position = UDim2.new(0.441379309, 0, 1.31818175, 0)
Discord.Size = UDim2.new(0, 170, 0, 22)
Discord.ZIndex = 4
Discord.AutoButtonColor = false
Discord.Font = Enum.Font.SourceSans
Discord.Text = "                  Join Discord Server"
Discord.TextColor3 = Color3.fromRGB(255, 255, 255)
Discord.TextSize = 14.000
Discord.TextXAlignment = Enum.TextXAlignment.Left

BlueLine.Name = "BlueLine"
BlueLine.Parent = Topbar
BlueLine.BackgroundColor3 = Color3.fromRGB(30, 85, 196)
BlueLine.BorderSizePixel = 0
BlueLine.Size = UDim2.new(0, 690, 0, 2)
BlueLine.ZIndex = 2

Title.Name = "Title"
Title.Parent = Topbar
Title.AnchorPoint = Vector2.new(0.5, 0)
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1.000
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0.5, 2, 0, 2)
Title.Size = UDim2.new(0, 200, 0, 31)
Title.Font = Enum.Font.SourceSans
Title.Text = "KRNL"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20.000

ScriptsBox.Name = "ScriptsBox"
ScriptsBox.Parent = Topbar
ScriptsBox.Active = true
ScriptsBox.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
ScriptsBox.BorderSizePixel = 0
ScriptsBox.Position = UDim2.new(0, 565, 0, 59)
ScriptsBox.Size = UDim2.new(0, 121, 0, 259)
ScriptsBox.ZIndex = 2
ScriptsBox.ScrollBarThickness = 8

UIListLayout_5.Parent = ScriptsBox

Example.Name = "Example"
Example.Parent = ScriptsBox
Example.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Example.BackgroundTransparency = 1.000
Example.BorderColor3 = Color3.fromRGB(0, 120, 215)
Example.BorderSizePixel = 0
Example.Size = UDim2.new(0, 120, 0, 16)
Example.ZIndex = 3
Example.Font = Enum.Font.SourceSans
Example.Text = "   Example.lua"
Example.TextColor3 = Color3.fromRGB(255, 255, 255)
Example.TextSize = 14.000
Example.TextXAlignment = Enum.TextXAlignment.Left

Execute.Name = "Execute"
Execute.Parent = Topbar
Execute.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
Execute.BorderSizePixel = 0
Execute.Position = UDim2.new(0, 4, 0, 321)
Execute.Size = UDim2.new(0, 99, 0, 24)
Execute.AutoButtonColor = false
Execute.Font = Enum.Font.Gotham
Execute.Text = "EXECUTE"
Execute.TextColor3 = Color3.fromRGB(255, 255, 255)
Execute.TextSize = 14.000

Clear.Name = "Clear"
Clear.Parent = Topbar
Clear.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
Clear.BorderSizePixel = 0
Clear.Position = UDim2.new(0, 107, 0, 321)
Clear.Size = UDim2.new(0, 99, 0, 24)
Clear.AutoButtonColor = false
Clear.Font = Enum.Font.Gotham
Clear.Text = "CLEAR"
Clear.TextColor3 = Color3.fromRGB(255, 255, 255)
Clear.TextSize = 14.000

OpenFile.Name = "OpenFile"
OpenFile.Parent = Topbar
OpenFile.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
OpenFile.BorderSizePixel = 0
OpenFile.Position = UDim2.new(0, 210, 0, 321)
OpenFile.Size = UDim2.new(0, 99, 0, 24)
OpenFile.AutoButtonColor = false
OpenFile.Font = Enum.Font.Gotham
OpenFile.Text = "OPEN FILE"
OpenFile.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenFile.TextSize = 14.000

SaveFile.Name = "SaveFile"
SaveFile.Parent = Topbar
SaveFile.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
SaveFile.BorderSizePixel = 0
SaveFile.Position = UDim2.new(0, 313, 0, 321)
SaveFile.Size = UDim2.new(0, 99, 0, 24)
SaveFile.AutoButtonColor = false
SaveFile.Font = Enum.Font.Gotham
SaveFile.Text = "SAVE FILE"
SaveFile.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveFile.TextSize = 14.000

Inject_2.Name = "Inject"
Inject_2.Parent = Topbar
Inject_2.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
Inject_2.BorderSizePixel = 0
Inject_2.Position = UDim2.new(0, 416, 0, 321)
Inject_2.Size = UDim2.new(0, 99, 0, 24)
Inject_2.AutoButtonColor = false
Inject_2.Font = Enum.Font.Gotham
Inject_2.Text = "INJECT"
Inject_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Inject_2.TextSize = 14.000

Options.Name = "Options"
Options.Parent = Topbar
Options.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
Options.BorderSizePixel = 0
Options.Position = UDim2.new(0, 586, 0, 321)
Options.Size = UDim2.new(0, 99, 0, 24)
Options.AutoButtonColor = false
Options.Font = Enum.Font.Gotham
Options.Text = "OPTIONS"
Options.TextColor3 = Color3.fromRGB(255, 255, 255)
Options.TextSize = 14.000

Editor.Name = "Editor"
Editor.Parent = Topbar
Editor.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
Editor.BorderSizePixel = 0
Editor.Position = UDim2.new(0, 5, 0, 76)
Editor.Size = UDim2.new(0, 554, 0, 241)

Line.Name = "Line"
Line.Parent = Editor
Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Line.Position = UDim2.new(0, 32, 0.00800000038, 0)
Line.Size = UDim2.new(0, 1, 0, 235)
Line.Visible = false

EditorScroll.Name = "EditorScroll"
EditorScroll.Parent = Editor
EditorScroll.Active = true
EditorScroll.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
EditorScroll.BorderSizePixel = 0
EditorScroll.Position = UDim2.new(0, 36, 0, 3)
EditorScroll.Size = UDim2.new(0, 515, 0, 235)
EditorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
EditorScroll.ScrollBarThickness = 6

Editor_2.Name = "Editor"
Editor_2.Parent = EditorScroll
Editor_2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Editor_2.BorderSizePixel = 0
Editor_2.Size = UDim2.new(0, 515, 0, 235)
Editor_2.ZIndex = 2
Editor_2.ClearTextOnFocus = false
Editor_2.Font = Enum.Font.Code
Editor_2.MultiLine = true
Editor_2.Text = ""
Editor_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Editor_2.TextSize = 14.000
Editor_2.TextXAlignment = Enum.TextXAlignment.Left
Editor_2.TextYAlignment = Enum.TextYAlignment.Top

NumberScroll.Name = "NumberScroll"
NumberScroll.Parent = Editor
NumberScroll.Active = true
NumberScroll.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
NumberScroll.BorderSizePixel = 0
NumberScroll.Position = UDim2.new(0, 3, 0, 3)
NumberScroll.Size = UDim2.new(0, 33, 0, 235)
NumberScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
NumberScroll.ScrollBarThickness = 0

Numbers.Name = "Numbers"
Numbers.Parent = NumberScroll
Numbers.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Numbers.BorderSizePixel = 0
Numbers.Size = UDim2.new(0, 33, 0, 235)
Numbers.ZIndex = 2
Numbers.Font = Enum.Font.Code
Numbers.Text = "1"
Numbers.TextColor3 = Color3.fromRGB(255, 255, 255)
Numbers.TextSize = 14.000
Numbers.TextYAlignment = Enum.TextYAlignment.Top

Logo.Name = "Logo"
Logo.Parent = Topbar
Logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Logo.BackgroundTransparency = 1.000
Logo.BorderSizePixel = 0
Logo.Position = UDim2.new(0, 5, 0, 6)
Logo.Size = UDim2.new(0, 22, 0, 22)
Logo.ZIndex = 2
Logo.Image = "rbxassetid://6763472823"

Close.Name = "Close"
Close.Parent = Topbar
Close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Close.BorderSizePixel = 0
Close.Position = UDim2.new(0, 655, 0, 2)
Close.Size = UDim2.new(0, 35, 0, 31)
Close.Image = "rbxassetid://6763508136"

Minimize.Name = "Minimize"
Minimize.Parent = Topbar
Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Minimize.BorderSizePixel = 0
Minimize.Position = UDim2.new(0, 620, 0, 2)
Minimize.Size = UDim2.new(0, 35, 0, 31)
Minimize.Image = "rbxassetid://6763473140"

ScriptTabs.Name = "ScriptTabs"
ScriptTabs.Parent = Topbar
ScriptTabs.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
ScriptTabs.BorderSizePixel = 0
ScriptTabs.ClipsDescendants = true
ScriptTabs.Position = UDim2.new(0, 5, 0, 60)
ScriptTabs.Size = UDim2.new(0, 522, 0, 16)

UIListLayout_6.Parent = ScriptTabs
UIListLayout_6.FillDirection = Enum.FillDirection.Horizontal
UIListLayout_6.SortOrder = Enum.SortOrder.LayoutOrder

Example1.Name = "Example1"
Example1.Parent = ScriptTabs
Example1.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
Example1.BorderSizePixel = 0
Example1.Size = UDim2.new(0, 84, 0, 16)

Close_2.Name = "Close"
Close_2.Parent = Example1
Close_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Close_2.BackgroundTransparency = 1.000
Close_2.BorderSizePixel = 0
Close_2.Position = UDim2.new(0, 68, 0, 0)
Close_2.Size = UDim2.new(0, 16, 0, 16)
Close_2.AutoButtonColor = false
Close_2.Font = Enum.Font.SourceSans
Close_2.Text = "X"
Close_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Close_2.TextSize = 16.000

Selecter.Name = "Selecter"
Selecter.Parent = Example1
Selecter.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Selecter.BackgroundTransparency = 1.000
Selecter.BorderSizePixel = 0
Selecter.Size = UDim2.new(0, 68, 0, 16)
Selecter.ZIndex = 2
Selecter.AutoButtonColor = false
Selecter.Font = Enum.Font.SourceSans
Selecter.Text = "Untitled.lua"
Selecter.TextColor3 = Color3.fromRGB(255, 255, 255)
Selecter.TextSize = 14.000

NewTab.Name = "NewTab"
NewTab.Parent = ScriptTabs
NewTab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
NewTab.BorderSizePixel = 0
NewTab.LayoutOrder = 1
NewTab.Size = UDim2.new(0, 16, 0, 16)
NewTab.AutoButtonColor = false
NewTab.Image = "rbxassetid://6763830018"

Fill.Name = "Fill"
Fill.Parent = Topbar
Fill.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
Fill.BorderSizePixel = 0
Fill.Position = UDim2.new(0, 527, 0, 60)
Fill.Size = UDim2.new(0, 32, 0, 16)

Open.Name = "Open"
Open.Parent = InternalGUI
Open.AnchorPoint = Vector2.new(0.5, 0.5)
Open.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Open.BorderSizePixel = 0
Open.Position = UDim2.new(0.5, 0, 0.5, 0)
Open.Size = UDim2.new(0, 50, 0, 50)
Open.Visible = false
Open.ZIndex = 20
Open.AutoButtonColor = false
Open.Image = "rbxassetid://6763472823"

UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = Open
end)


function DrawingLib.createScreenGui()
	local screenGuiObj = ({
		IgnoreGuiInset = true,
		DisplayOrder = 0,
		ResetOnSpawn = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = true
	} + baseDrawingObj)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = drawingIndex
	screenGui.IgnoreGuiInset = screenGuiObj.IgnoreGuiInset
	screenGui.DisplayOrder = screenGuiObj.DisplayOrder
	screenGui.ResetOnSpawn = screenGuiObj.ResetOnSpawn
	screenGui.ZIndexBehavior = screenGuiObj.ZIndexBehavior
	screenGui.Enabled = screenGuiObj.Enabled

	screenGui.Parent = coreGui

	return setmetatable({Parent = coreGui}, {
		__newindex = function(_, index, value)
			if screenGuiObj[index] == nil then
				warn("Invalid property: " .. tostring(index))
				return
			end

			if index == "IgnoreGuiInset" then
				screenGui.IgnoreGuiInset = value
			elseif index == "DisplayOrder" then
				screenGui.DisplayOrder = value
			elseif index == "ResetOnSpawn" then
				screenGui.ResetOnSpawn = value
			elseif index == "ZIndexBehavior" then
				screenGui.ZIndexBehavior = value
			elseif index == "Enabled" then
				screenGui.Enabled = value
			elseif index == "Parent" then
				screenGui.Parent = value
			end
			screenGuiObj[index] = value
		end,
		__index = function(self, index)
			if index == "Remove" or index == "Destroy" then
				return function()
					screenGui:Destroy()
					screenGuiObj:Remove()
				end
			end
			return screenGuiObj[index]
		end,
		__tostring = function() return "Drawing" end
	})
end



function DrawingLib.createTextButton()
	local buttonObj = ({
		Text = "Button",
		Font = DrawingLib.Fonts.UI,
		Size = 20,
		Position = UDim2.new(0, 0, 0, 0),
		Color = Color3.new(1, 1, 1),
		BackgroundColor = Color3.new(0.2, 0.2, 0.2),
		Transparency = 0,
		Visible = true,
		ZIndex = 1,
		MouseButton1Click = nil
	} + baseDrawingObj)

	local button = Instance.new("TextButton")
	button.Name = drawingIndex
	button.Text = buttonObj.Text
	button.FontFace = getFontFromIndex(buttonObj.Font)
	button.TextSize = buttonObj.Size
	button.Position = buttonObj.Position
	button.TextColor3 = buttonObj.Color
	button.BackgroundColor3 = buttonObj.BackgroundColor
	button.BackgroundTransparency = convertTransparency(buttonObj.Transparency)
	button.Visible = buttonObj.Visible
	button.ZIndex = buttonObj.ZIndex

	button.Parent = drawingUI

	local buttonEvents = {}

	return setmetatable({
		Parent = drawingUI,
		Connect = function(_, eventName, callback)
			if eventName == "MouseButton1Click" then
				if buttonEvents["MouseButton1Click"] then
					buttonEvents["MouseButton1Click"]:Disconnect()
				end
				buttonEvents["MouseButton1Click"] = button.MouseButton1Click:Connect(callback)
			else
				warn("Invalid event: " .. tostring(eventName))
			end
		end
	}, {
		__newindex = function(_, index, value)
			if buttonObj[index] == nil then
				warn("Invalid property: " .. tostring(index))
				return
			end

			if index == "Text" then
				button.Text = value
			elseif index == "Font" then
				button.FontFace = getFontFromIndex(math.clamp(value, 0, 3))
			elseif index == "Size" then
				button.TextSize = value
			elseif index == "Position" then
				button.Position = value
			elseif index == "Color" then
				button.TextColor3 = value
			elseif index == "BackgroundColor" then
				button.BackgroundColor3 = value
			elseif index == "Transparency" then
				button.BackgroundTransparency = convertTransparency(value)
			elseif index == "Visible" then
				button.Visible = value
			elseif index == "ZIndex" then
				button.ZIndex = value
			elseif index == "Parent" then
				button.Parent = value
			elseif index == "MouseButton1Click" then
				if typeof(value) == "function" then
					if buttonEvents["MouseButton1Click"] then
						buttonEvents["MouseButton1Click"]:Disconnect()
					end
					buttonEvents["MouseButton1Click"] = button.MouseButton1Click:Connect(value)
				else
					warn("Invalid value for MouseButton1Click: expected function, got " .. typeof(value))
				end
			end
			buttonObj[index] = value
		end,
		__index = function(self, index)
			if index == "Remove" or index == "Destroy" then
				return function()
					button:Destroy()
					buttonObj:Remove()
				end
			end
			return buttonObj[index]
		end,
		__tostring = function() return "Drawing" end
	})
end

function DrawingLib.createTextLabel()
	local labelObj = ({
		Text = "Label",
		Font = DrawingLib.Fonts.UI,
		Size = 20,
		Position = UDim2.new(0, 0, 0, 0),
		Color = Color3.new(1, 1, 1),
		BackgroundColor = Color3.new(0.2, 0.2, 0.2),
		Transparency = 0,
		Visible = true,
		ZIndex = 1
	} + baseDrawingObj)

	local label = Instance.new("TextLabel")
	label.Name = drawingIndex
	label.Text = labelObj.Text
	label.FontFace = getFontFromIndex(labelObj.Font)
	label.TextSize = labelObj.Size
	label.Position = labelObj.Position
	label.TextColor3 = labelObj.Color
	label.BackgroundColor3 = labelObj.BackgroundColor
	label.BackgroundTransparency = convertTransparency(labelObj.Transparency)
	label.Visible = labelObj.Visible
	label.ZIndex = labelObj.ZIndex

	label.Parent = drawingUI

	return setmetatable({Parent = drawingUI}, {
		__newindex = function(_, index, value)
			if labelObj[index] == nil then
				warn("Invalid property: " .. tostring(index))
				return
			end

			if index == "Text" then
				label.Text = value
			elseif index == "Font" then
				label.FontFace = getFontFromIndex(math.clamp(value, 0, 3))
			elseif index == "Size" then
				label.TextSize = value
			elseif index == "Position" then
				label.Position = value
			elseif index == "Color" then
				label.TextColor3 = value
			elseif index == "BackgroundColor" then
				label.BackgroundColor3 = value
			elseif index == "Transparency" then
				label.BackgroundTransparency = convertTransparency(value)
			elseif index == "Visible" then
				label.Visible = value
			elseif index == "ZIndex" then
				label.ZIndex = value
			elseif index == "Parent" then
				label.Parent = value
			end
			labelObj[index] = value
		end,
		__index = function(self, index)
			if index == "Remove" or index == "Destroy" then
				return function()
					label:Destroy()
					labelObj:Remove()
				end
			end
			return labelObj[index]
		end,
		__tostring = function() return "Drawing" end
	})
end

function DrawingLib.createTextBox()
	local boxObj = ({
		Text = "",
		Font = DrawingLib.Fonts.UI,
		Size = 20,
		Position = UDim2.new(0, 0, 0, 0),
		Color = Color3.new(1, 1, 1),
		BackgroundColor = Color3.new(0.2, 0.2, 0.2),
		Transparency = 0,
		Visible = true,
		ZIndex = 1
	} + baseDrawingObj)

	local textBox = Instance.new("TextBox")
	textBox.Name = drawingIndex
	textBox.Text = boxObj.Text
	textBox.FontFace = getFontFromIndex(boxObj.Font)
	textBox.TextSize = boxObj.Size
	textBox.Position = boxObj.Position
	textBox.TextColor3 = boxObj.Color
	textBox.BackgroundColor3 = boxObj.BackgroundColor
	textBox.BackgroundTransparency = convertTransparency(boxObj.Transparency)
	textBox.Visible = boxObj.Visible
	textBox.ZIndex = boxObj.ZIndex

	textBox.Parent = drawingUI

	return setmetatable({Parent = drawingUI}, {
		__newindex = function(_, index, value)
			if boxObj[index] == nil then
				warn("Invalid property: " .. tostring(index))
				return
			end

			if index == "Text" then
				textBox.Text = value
			elseif index == "Font" then
				textBox.FontFace = getFontFromIndex(math.clamp(value, 0, 3))
			elseif index == "Size" then
				textBox.TextSize = value
			elseif index == "Position" then
				textBox.Position = value
			elseif index == "Color" then
				textBox.TextColor3 = value
			elseif index == "BackgroundColor" then
				textBox.BackgroundColor3 = value
			elseif index == "Transparency" then
				textBox.BackgroundTransparency = convertTransparency(value)
			elseif index == "Visible" then
				textBox.Visible = value
			elseif index == "ZIndex" then
				textBox.ZIndex = value
			elseif index == "Parent" then
				textBox.Parent = value
			end
			boxObj[index] = value
		end,
		__index = function(self, index)
			if index == "Remove" or index == "Destroy" then
				return function()
					textBox:Destroy()
					boxObj:Remove()
				end
			end
			return boxObj[index]
		end,
		__tostring = function() return "Drawing" end
	})
end

local drawingFunctions = {}

function drawingFunctions.isrenderobj(drawingObj)
	local success, isrenderobj = pcall(function()
		return drawingObj.Parent == drawingUI
	end)
	if not success then return false end
	return isrenderobj
end

function drawingFunctions.getrenderproperty(drawingObj, property)
	local success, drawingProperty  = pcall(function()
		return drawingObj[property]
	end)
	if not success then return end

	if drawingProperty ~= nil then
		return drawingProperty
	end
end

function drawingFunctions.setrenderproperty(drawingObj, property, value)
	assert(drawingFunctions.getrenderproperty(drawingObj, property), "'" .. tostring(property) .. "' is not a valid property of " .. tostring(drawingObj) .. ", " .. tostring(typeof(drawingObj)))
	drawingObj[property]  = value
end

function drawingFunctions.cleardrawcache()
	for _, drawing in drawingUI:GetDescendants() do
		drawing:Remove()
	end
end

return {Drawing = DrawingLib, functions = drawingFunctions}
