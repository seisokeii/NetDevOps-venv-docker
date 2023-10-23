# NetDevOps Docker Image For Runner Executor 

此 Image 主要是為了給 Gitlab CI Runner 去跑的環境 (executor)，自己要開發的話也可以使用 pyproject.toml 去安裝對應環境．

## DIFF / PATCH 指令

### Diff

可以使用以下指令去查看 poetry 的路徑

```
poetry env info --path
```

需要先修改完一份 (custom_gns3fy.py)，接下來進到 docker 裡面去或是與 docker 相同的作業系統使用以下指令

```
diff -uN $(poetry env info --path)/lib/python3.9/site-packages/gns3fy/gns3fy.py custom_gns3fy.py > gns3fy.patch
```

### patch

此指令可以直接寫在 Dockerfile 內

```
patch -fs $(poetry env info --path)/lib/python3.9/site-packages/nornir_jinja2/plugins/tasks/template_file.py patch_nornir_jinja2.patch
```

## 更新方式

### 1. 自行安裝 poetry 套件

### 2. 下載 pyproject.toml

```
$ git clone https://gitlab.cs.nctu.edu.tw/net/netdevops/images.git
```

### 3. 使用 Poetry 更新升級

```
$ poetry update
```

### 4. 更新 GitLab

```
$ git push
```

### 5. 更新 NetDevOps 的 Container Registry

- 點進去 NetDevOps 專案，左邊 taskbar 選擇 Deploy -> Container Registry 
- 接著照著上面的三個指令下即可

***

## 套件問題

### 1. Nornir Jinja JSON/XML 排版

因為 jinja2 產模板的時候想要縮排方便之後 debug 所以特此修改套件原始碼，有空再整理程式碼發 PR 給官方

p.s. 修改完後如果印出時一樣跑版代表模板有語法錯誤，並不是 json/xml

要修改的檔案是 nornir_jinja2/plugins/tasks/template_file.py 這個檔案，屬於 nornir_jinja2 套件
``` python
import json
import xml.etree.ElementTree as elementTree
import xml.dom.minidom as minidom
import re


def template_file(~~~~~
	...
	...
	t = env.get_template(template)
	text = t.render(host=task.host, **kwargs)

    ### 'a 加入以下程式碼到此 function 最下方 'a ###
    res_json = is_json(text)
    if res_json:
        data = json.loads(text)
        reform = json.dumps(data, indent=4)

        return Result(host=task.host, result=reform)

    res_xml = is_xml(text)
    if res_xml:
        xml = minidom.parseString(text)
        reform = xml.toprettyxml(indent="      ") # 六個空白輸出會比較好看
        reform = re.sub(r'^<\?xml.*?\?>', '', reform).strip() # 刪除 XML 聲明
        reform = re.sub(r'\n\s*\n', '\n', reform) # 刪除空白行
        reform = re.sub(r'&quot;', '"', reform) # 把雙引號給轉回來

        return Result(host=task.host, result=reform)
    ### 'a 以上是要加入的程式碼 'a ###
	return Result(host=task.host, result=text) # 這行是原始的不用加


def is_json(text):
    try:
        json.loads(text)
    except ValueError as e:
        return False
    return True


def is_xml(text):
    try:
        elementTree.fromstring(text)
    except elementTree.ParseError as e:
        return False
    return True
```

### 2. gns3fy

gns3fy 0.8.0 這個版本有 pydantic 1.9.2 版本的問題，在操作 create(), create_node(), create_link() 的時候會出現以下錯誤訊息  

```
Error message: 
requests.exceptions.HTTPError: 400: JSON schema error with API request '/v2/projects' and JSON data '{'name': 'test-script', '__pydantic_initialised__': True}': \ 
    Additional properties are not allowed ('__pydantic_initialised__' was unexpected)
```

需要在套件的 create(), create_node(), create_link() 附近加上以下 code 去修復 
```
del data['__pydantic_initialised__']
```

***