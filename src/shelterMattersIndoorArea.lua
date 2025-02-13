local modDirectory = g_currentModDirectory

ShelterMattersIndoorArea = {}

function ShelterMattersIndoorArea.prerequisitesPresent(specializations)
	return true
end

function ShelterMattersIndoorArea.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", ShelterMattersIndoorArea)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", ShelterMattersIndoorArea)
end

function ShelterMattersIndoorArea.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateNavMeshMaterial", ShelterMattersIndoorArea.updateNavMeshMaterial)
	SpecializationUtil.registerFunction(placeableType, "navMeshMaterialLoaded", ShelterMattersIndoorArea.navMeshMaterialLoaded)
end


function ShelterMattersIndoorArea.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("ShelterMattersIndoorArea")

    ObjectChangeUtil.registerObjectChangesXMLPaths(schema, "placeable.base")

	schema:register(XMLValueType.NODE_INDEX, "placeable.placement#collision", "Collision node")

	basePath = basePath .. ".navMesh"
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#planeNode", "Node for navMesh")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#root", "Root node for navMesh")

    schema:setXMLSpecializationType()
end

function ShelterMattersIndoorArea:onLoad(savegame)
    local spec = {}
    self.spec_shelterMattersIndoorArea = spec
    local xmlFile = self.xmlFile

    local objectChanges = {}

	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "placeable.base.objectChanges", objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(objectChanges, true)

	spec.root = xmlFile:getValue("placeable.navMesh#root", nil, self.components, self.i3dMappings)
	spec.navMeshPlane = xmlFile:getValue("placeable.navMesh#planeNode", nil, self.components, self.i3dMappings)
	spec.collision = xmlFile:getValue("placeable.placement#collision", nil, self.components, self.i3dMappings)

    spec.helperNavMeshPlane = clone(spec.navMeshPlane, true, false, false)

    setVisibility(spec.helperNavMeshPlane, ShelterMatters.shouldShowIndoorAreas or false)
    local x, y, z = getTranslation(spec.helperNavMeshPlane)
    setTranslation(spec.helperNavMeshPlane, x, y + 0.5--[[ g_ep_constructionActions.currentHeight]], z)
end

function ShelterMattersIndoorArea:onDelete()
    local pastureSystem = g_currentMission.pastureSystem
    local spec = self.spec_shelterMattersIndoorArea
    if spec.navMeshMaterialLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(spec.navMeshMaterialLoadRequestId)
	end
end

function ShelterMattersIndoorArea:updateNavMeshMaterial()
    local spec = self.spec_shelterMattersIndoorArea
    local navMeshMaterialFilename = Utils.getFilename("materials/navMeshMaterial.i3d", modDirectory)
    local loadingTask = self:createLoadingTask(spec)
    local arguments = {
        loadingTask = loadingTask
    }
    spec.navMeshMaterialLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(navMeshMaterialFilename, true, false, self.navMeshMaterialLoaded, self, arguments)
end

function ShelterMattersIndoorArea:navMeshMaterialLoaded(node, failedReason, args)
    if node == nil then
        Logging.error("Could not load navMeshMaterial")
        return
    end

    local spec = self.spec_shelterMattersIndoorArea
    local navMeshMaterialId = I3DUtil.indexToObject(node, "0")
    local navMeshMaterial = getMaterial(navMeshMaterialId, 0)
    setMaterial(spec.helperNavMeshPlane, navMeshMaterial, 0)
    setIsNonRenderable(spec.helperNavMeshPlane, false)

	local loadingTask = args.loadingTask
	delete(node)
	self:finishLoadingTask(loadingTask)
end
