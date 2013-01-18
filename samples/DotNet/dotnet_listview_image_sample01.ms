--------------------------------------------------------------------------
-- dotnet_listview_image_sample01.ms
--------------------------------------------------------------------------
-- DotNetのListViewを使った画像一覧表示のサンプルコード
-- 指定したフォルダの画像を一覧表示します。
-- 画像間の隙間の調整用コードと、
-- 画像のドラッグ＆ドロップによる並び替え用コードを含んでいます。


(
	local window
	local imagePath = @"D:\Image\*.jpg"

	rollout window "ListView ImageList Test" (
		dotNetControl lv "System.Windows.Forms.ListView" width:470 height:500 pos:[0, 0]


		--リストビューイメージ間の空白サイズ取得
		fn getSpaceSize imageSize space = (
			local sizeX	= (imageSize + space.X)			--横
			local sizeY = (imageSize + space.Y + 4)		--縦（4は最小スペース）
			(sizeX + sizeY * 65536)						--32 ビット整数値に変換
		)
		--リストビューイメージ間の空白設定
		fn setListViewImageSpace lv size = (
			Windows.sendMessage (lv.handle) (0x1000 + 53) 0 size
		)
		--リストビュー初期化
		fn initListView = (
			lv.MultiSelect			= false
			lv.AutoArrange			= true
			lv.InsertionMark.Color	= (dotNetClass "System.Drawing.Color").Green
			lv.AllowDrop			= True
			lv.Columns.add "idx"	50
			lv.Columns.add "text"	400

			lv.View					= (dotNetClass "System.Windows.Forms.View").LargeIcon
			setListViewImageSpace lv (getSpaceSize 100 [10, 30])
		)
		--ImageList 生成
		fn createImageList size = (
			local imglist			= (dotNetObject	"System.Windows.Forms.ImageList")
			imglist.ImageSize		= (dotNetObject	"System.Drawing.Size" size.x size.y)
			imglist.ColorDepth		= (dotNetClass	"System.Windows.Forms.ColorDepth").Depth32Bit
			imglist
		)
		--数値のゼロパディング
		fn padNum num = (
			formattedPrint num format:"05d"
		)
		--行データ追加
		fn addListViewRow idx txt = (
			local rowIdx = (idx - 1)
			lv.Items.add (padNum rowIdx) rowIdx
			lv.Items.item[rowIdx].subitems.add(txt)
		)
		--リストビューデータ表示
		fn loadListView = (
			local imgFiles = (getFiles imagePath)
			if (imgFiles.count == 0) do ( return false )

			lv.BeginUpdate()

			--画像項目を追加
			local imgClass		= dotNetClass "System.Drawing.Image"
			lv.LargeImageList	= createImageList [100, 100]
			for idx = 1 to imgFiles.Count do (
				local thumb = (imgClass.FromFile imgfiles[idx])
				lv.LargeImageList.images.add(thumb)
				thumb.Dispose()
			)

			--行項目を追加
			lv.items.clear()
			for idx = 1 to imgFiles.Count do (
				addListViewRow idx imgFiles[idx]
			)

			lv.EndUpdate()
		)
		--リストビューソート
		fn sortListView = (
			for idx = 0 to (lv.items.count - 1) do ( lv.items.item[idx].text = (padNum idx) )
			lv.ListViewItemSorter = dotnetobject "MXS_dotNet.ListViewItemComparer" 0
			lv.ListViewItemSorter = undefined
		)

		--Window 表示
		on window open do (
			initListView()
			loadListView()
		)
		--ドラッグ操作
		on lv ItemDrag sender e do (
			lv.DoDragDrop e.Item (dotNetClass "System.Windows.Forms.DragDropEffects").Move
		)
		--ドラッグエフェクト設定
		on lv DragEnter sender e do (
			e.Effect = e.AllowedEffect
		)
		--ドロップ位置描画
		on lv DragOver sender e do (
			--マウスポインタに最も近いアイテムを特定
			local targetPoint = (lv.PointToClient (dotNetObject "System.Drawing.Point" e.X e.Y))
			local targetIndex = (lv.InsertionMark.NearestIndex targetPoint)

			lv.InsertionMark.Index = targetIndex

			--特定アイテムの左右どちらにマーカー表示するかを設定
			if (targetIndex >= 0) do (
				local itemBounds = (lv.GetItemRect targetIndex)
				if (targetPoint.X > itemBounds.Left + (itemBounds.Width / 2)) then (
					lv.InsertionMark.AppearsAfterItem = True
				) else (
					lv.InsertionMark.AppearsAfterItem = False
				)
			)
		)
		--ドロップ放棄
		on lv DragLeave sender e do (
			lv.InsertionMark.Index = -1
		)
		--ドロップ操作
		on lv DragDrop sender e do (
			local targetIndex = lv.InsertionMark.Index
			if (targetIndex == -1) do ( return false )

			if (lv.InsertionMark.AppearsAfterItem) do ( targetIndex += 1 )

			--ドラッグアイテムをドロップ場所へ移動
			local classLvi	= (dotNetClass "System.Windows.Forms.ListViewItem")
			local dragItem	= (dotnet.ValueToDotNetObject (e.Data.GetData classLvi) classLvi)
			lv.items.insert targetIndex (dotnet.ValueToDotNetObject (dragItem.Clone()) classLvi)
			lv.items.remove dragItem

			--ImageListの場合は再ソートが必要
			sortListView()
		)

	)

	createDialog window width:470 height:500
)