<%--
/**
 * Copyright (c) 2000-present Liferay, Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation; either version 2.1 of the License, or (at your option)
 * any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
 * details.
 */
--%>

<%@ include file="/html/portlet/search/init.jsp" %>

<%
ResultRow row = (ResultRow)request.getAttribute(WebKeys.SEARCH_CONTAINER_RESULT_ROW);

Document document = (Document)row.getObject();

String className = document.get(Field.ENTRY_CLASS_NAME);
long classPK = GetterUtil.getLong(document.get(Field.ENTRY_CLASS_PK));

String downloadURL = null;

PortletURL viewFullContentURL = renderResponse.createRenderURL();

viewFullContentURL.setParameter("struts_action", "/search/view_content");
viewFullContentURL.setParameter("redirect", currentURL);
viewFullContentURL.setPortletMode(PortletMode.VIEW);
viewFullContentURL.setWindowState(WindowState.MAXIMIZED);

String viewURL = null;

AssetRendererFactory assetRendererFactory = AssetRendererFactoryRegistryUtil.getAssetRendererFactoryByClassName(className);

AssetRenderer assetRenderer = null;

boolean inheritRedirect = false;

if (assetRendererFactory != null) {
	long resourcePrimKey = GetterUtil.getLong(document.get(Field.ROOT_ENTRY_CLASS_PK));

	if (resourcePrimKey > 0) {
		classPK = resourcePrimKey;
	}

	AssetEntry assetEntry = AssetEntryLocalServiceUtil.getEntry(className, classPK);

	assetRenderer = assetRendererFactory.getAssetRenderer(classPK);

	downloadURL = assetRenderer.getURLDownload(themeDisplay);

	viewFullContentURL.setParameter("assetEntryId", String.valueOf(assetEntry.getEntryId()));
	viewFullContentURL.setParameter("type", assetRendererFactory.getType());

	if (searchDisplayContext.isViewInContext() || !assetEntry.isVisible()) {
		inheritRedirect = true;

		String viewFullContentURLString = viewFullContentURL.toString();

		viewFullContentURLString = HttpUtil.setParameter(viewFullContentURLString, "redirect", currentURL);

		viewURL = assetRenderer.getURLViewInContext(liferayPortletRequest, liferayPortletResponse, viewFullContentURLString);

		viewURL = AssetUtil.checkViewURL(assetEntry, searchDisplayContext.isViewInContext(), viewURL, currentURL, themeDisplay);
	}
	else {
		viewURL = viewFullContentURL.toString();
	}
}
else {
	viewURL = viewFullContentURL.toString();
}

Indexer indexer = IndexerRegistryUtil.getIndexer(className);

Summary summary = null;

if (indexer != null) {
	String snippet = document.get(Field.SNIPPET);

	summary = indexer.getSummary(document, snippet, viewFullContentURL, renderRequest, renderResponse);
}
else if (assetRenderer != null) {
	summary = new Summary(locale, assetRenderer.getTitle(locale), assetRenderer.getSearchSummary(locale), viewFullContentURL);
}
%>

<c:if test="<%= summary != null %>">

	<%
	if ((assetRendererFactory == null) && searchDisplayContext.isViewInContext()) {
		viewURL = viewFullContentURL.toString();
	}

	viewURL = searchDisplayContext.checkViewURL(viewURL, currentURL, inheritRedirect);

	boolean highlightEnabled = (Boolean)request.getAttribute("search.jsp-highlightEnabled");
	String[] queryTerms = (String[])request.getAttribute("search.jsp-queryTerms");

	summary.setHighlight(highlightEnabled);
	summary.setQueryTerms(queryTerms);
	%>

	<span class="asset-entry">
		<span class="asset-entry-type">
			<%= ResourceActionsUtil.getModelResource(themeDisplay.getLocale(), className) %>

			<c:if test="<%= locale != summary.getLocale() %>">

				<%
				Locale summaryLocale = summary.getLocale();
				%>

				<liferay-ui:icon image='<%= "../language/" + LocaleUtil.toLanguageId(summaryLocale) %>' message='<%= LanguageUtil.format(locale, "this-result-comes-from-the-x-version-of-this-content", summaryLocale.getDisplayLanguage(locale), false) %>' />
			</c:if>
		</span>

		<span class="asset-entry-title">
			<a class="<%= (assetRenderer != null) ? assetRenderer.getIconCssClass() : StringPool.BLANK %>" href="<%= viewURL %>">
				<%= summary.getHighlightedTitle() %>
			</a>

			<c:if test="<%= Validator.isNotNull(downloadURL) %>">
				<liferay-ui:icon
					iconCssClass="icon-download-alt"
					label="<%= false %>"
					message='<%= LanguageUtil.format(request, "download-x", HtmlUtil.escape(summary.getTitle()), false) %>'
					method="get"
					url="<%= downloadURL %>"
				/>
			</c:if>
		</span>

		<%
		AssetEntry assetEntry = AssetEntryLocalServiceUtil.fetchEntry(className, classPK);
		%>

		<c:if test="<%= Validator.isNotNull(summary.getContent()) || ((assetEntry != null) && (ArrayUtil.isNotEmpty(assetEntry.getCategoryIds()) || ArrayUtil.isNotEmpty(assetEntry.getTagNames()))) %>">
			<div class="asset-entry-content">
				<c:if test="<%= Validator.isNotNull(summary.getContent()) %>">
					<span class="asset-entry-summary">
						<%= summary.getHighlightedContent() %>
					</span>
				</c:if>

				<c:if test="<%= assetEntry != null %>">

					<%
					PortletURL portletURL = (PortletURL)request.getAttribute("search.jsp-portletURL");
					%>

					<liferay-ui:asset-tags-summary
						className="<%= className %>"
						classPK="<%= classPK %>"
						paramName="<%= Field.ASSET_TAG_NAMES %>"
						portletURL="<%= PortletURLUtil.clone(portletURL, renderResponse) %>"
					/>

					<liferay-ui:asset-categories-summary
						className="<%= className %>"
						classPK="<%= classPK %>"
						paramName="<%= Field.ASSET_CATEGORY_IDS %>"
						portletURL="<%= PortletURLUtil.clone(portletURL, renderResponse) %>"
					/>
				</c:if>
			</div>
		</c:if>
	</span>
</c:if>