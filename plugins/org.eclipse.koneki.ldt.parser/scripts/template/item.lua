--------------------------------------------------------------------------------
--  Copyright (c) 2012 Sierra Wireless.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the Eclipse Public License v1.0
--  which accompanies this distribution, and is available at
--  http://www.eclipse.org/legal/epl-v10.html
-- 
--  Contributors:
--       Kevin KIN-FOO <kkinfoo@sierrawireless.com>
--           - initial API and implementation and initial documentation
--------------------------------------------------------------------------------
return 
[[<dl class="function">
<dt>
# if _item.type and _item.type.tag == 'internaltyperef' then
	<em>$(_item.type and '#'..(_item.type.typename or ''))</em>
# end
$(_item.name)</dt>
# if _item.shortdescription then
	<dd>$( markdown(_item.shortdescription) )</dd>
# end
# if markdown(_item.description) then
	<dd>$( markdown(_item.description) )</dd>
# end
</dl>]]
