BEGIN TRAN
DECLARE @SourceExtension INT = 1148
        ,@DestinationExtension INT = 1265
        ,@WhatToCopy VARCHAR(255) = 'Console Buttons' --Console Buttons,Contact Favourites,Extension Favourites,Queue Favourites,Shortcuts



--DON'T CHANGE ANYTHING BELOW HERE!!!



DECLARE @OriginalSourceParentGUID VARCHAR(50),
		@OriginalDestinationParentGUID VARCHAR(50)

SELECT @OriginalSourceParentGUID = Grouplistid from tblGroupLists where Extension = @SourceExtension and Description = @WhatToCopy
SELECT @OriginalDestinationParentGUID = Grouplistid from tblGroupLists where Extension = @DestinationExtension and Description = @WhatToCopy


;with	DeepCopy_NewData AS
(
	select	Description as ParentDescription,
			* 
	from	tblGroupLists
	where	ParentID = ''
	UNION ALL
	SELECT	DeepCopy_NewData.ParentDescription
			, tblGroupLists.*
	FROM	tblGroupLists
	JOIN	DeepCopy_NewData
		ON	DeepCopy_NewData.GroupListID = tblGroupLists.ParentID
)
SELECT	* 
INTO	#AllItemsToCopy
FROM	DeepCopy_NewData
WHERE	Extension = @SourceExtension
	AND ParentDescription = @WhatToCopy


;with	DeepCopy_ExistingData AS
(
	select	Description as ParentDescription,
			* 
	from	tblGroupLists
	where	ISNULL(ParentID,'') = ''
	UNION ALL
	SELECT	DeepCopy_ExistingData.ParentDescription
			, tblGroupLists.*
	FROM	tblGroupLists
	JOIN	DeepCopy_ExistingData
		ON	DeepCopy_ExistingData.GroupListID = tblGroupLists.ParentID
)
SELECT	* 
INTO	#AllItemsToDelete
FROM	DeepCopy_ExistingData
WHERE	Extension = @DestinationExtension
	AND ParentDescription = @WhatToCopy


delete		tblGroupLists
from		tblGroupLists
INNER JOIN	#AllItemsToDelete
		ON	#AllItemsToDelete.GroupListID = tblGroupLists.GroupListID

--SELECT * FROM tblGroupLists where Extension = @DestinationExtension


SELECT GroupListID as originalGUID, '{' + CAST(NEWID() as varchar(48)) + '}' as newGUID
into #newGUIDs
FROM 
(
	SELECT	distinct Grouplistid
	FROM	#AllItemsToCopy
)as rawData

UPDATE #newGUIDs
SET newGUID = @OriginalDestinationParentGUID
WHERE originalGUID = @OriginalSourceParentGUID


INSERT INTO tblGroupLists
SELECT	newGroupListID.newGUID, @DestinationExtension, ServerID, CASE WHEN LEN(newParentListID.newGUID)>1 THEN newParentListID.newGUID ELSE '' END, CASE WHEN ObjectType = 21 THEN newGroupListID.newGUID ELSE ObjectID END, ObjectType, AdditionalData, Description, NonIdentifyingData, SortType

FROM		#AllItemsToCopy
INNER JOIN	#newGUIDs as newGroupListID
		ON	newGroupListID.originalGUID = #AllItemsToCopy.GroupListID
LEFT JOIN	#newGUIDs as newParentListID
		ON	newParentListID.originalGUID = #AllItemsToCopy.ParentID


drop table #AllItemsToCopy
drop table #AllItemsToDelete
drop table #newGUIDs


COMMIT TRAN