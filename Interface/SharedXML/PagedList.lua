
PagedListMixin = CreateFromMixins(CallbackRegistryMixin);

PagedListMixin:GenerateCallbackEvents(
{
	"ListRefreshed",
});

function PagedListMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self);
end

function PagedListMixin:SetLayout(layout, numElements)
	if self.layout ~= nil then
		return;
	end

	self.layout = layout;
	self.numElements = numElements;
end

function PagedListMixin:CanInitialize()
	return (self.layout ~= nil) and (self.numElements ~= nil);
end

function PagedListMixin:InitializeList()
	self.page = 1;
	self.elements = {};

	local template = self:GetElementTemplate();
	local function PagedListFactoryFunction(index)
		local newFrame = CreateFrame("BUTTON", nil, self, template);
		table.insert(self.elements, newFrame);
		return newFrame;
	end

	local initialAnchor = AnchorUtil.CreateAnchor("TOPLEFT", self, "TOPLEFT");
	AnchorUtil.GridLayoutFactoryByCount(PagedListFactoryFunction, self.numElements, initialAnchor, self.layout);
end

function PagedListMixin:GetNumElementFrames()
	return #self.elements;
end

function PagedListMixin:GetElementFrame(frameIndex)
	return self.elements[frameIndex];
end

function PagedListMixin:GetListOffset()
	return self:GetNumElementFrames() * (self:GetPage() - 1);
end

function PagedListMixin:ResetDisplay()
	self:SetPage(1);
end

function PagedListMixin:SetPage(pageIndex)
	self.page = pageIndex;
	self:RefreshListDisplay();
end

function PagedListMixin:GetPage()
	return self.page;
end

function PagedListMixin:GetLastPage()
	return math.ceil(self.getNumResultsFunction() / self:GetNumElementFrames());
end

function PagedListMixin:CanDisplay()
	if (self.layout == nil) or (self.numElements == nil) then
		return false, "Templated list layout not set. Use PagedListMixin:SetLayout.";
	end

	return TemplatedListMixin.CanDisplay(self);
end

function PagedListMixin:RefreshListDisplay()
	TemplatedListMixin.RefreshListDisplay(self);

	self:TriggerEvent(PagedListMixin.Event.ListRefreshed);
end


PagedListControlButtonMixin = {};

function PagedListControlButtonMixin:OnClick()
	self:GetParent():ChangePage(self.pageAdjustment);
end


PagedListControlMixin = {};

function PagedListControlMixin:OnShow()
	self.pagedList:RegisterCallback(PagedListMixin.Event.ListRefreshed, self.OnListRefreshed, self);
	self:RefreshPaging();
end

function PagedListControlMixin:OnHide()
	self.pagedList:UnregisterCallback(PagedListMixin.Event.ListRefreshed, self);
end

function PagedListControlMixin:SetPagedList(pagedList)
	if self.pagedList ~= nil then
		return;
	end

	self.pagedList = pagedList;
end

function PagedListControlMixin:GetPagedList()
	return self.pagedList;
end

function PagedListControlMixin:OnListRefreshed()
	self:RefreshPaging();
end

function PagedListControlMixin:RefreshPaging()
	local pagedList = self:GetPagedList();
	local currentPage = pagedList:GetPage();
	local lastPage = pagedList:GetLastPage();

	self.ForwardButton:SetEnabled(currentPage ~= lastPage);
	self.BackwardButton:SetEnabled(currentPage ~= 1);

	-- Hide the control with alpha so we stay registered for event callbacks.
	local shouldBeHidden = not self.alwaysShow and (lastPage == 1);
	self:SetAlpha(shouldBeHidden and 0 or 1);
	if shouldBeHidden then
		return;
	end

	self.PageText:SetText(PAGED_LIST_PAGING_FORMAT:format(currentPage, lastPage));

	self:MarkDirty();
end

function PagedListControlMixin:ChangePage(pageAdjustment)
	local pagedList = self:GetPagedList();
	local currentPage = pagedList:GetPage();
	local lastPage = pagedList:GetLastPage();
	local newPage = math.clamp(currentPage + pageAdjustment, 1, lastPage);
	if newPage ~= currentPage then
		pagedList:SetPage(newPage);
	end
end
