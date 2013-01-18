--------------------------------------------------------------------------
-- dotnet_listview_image_sample01.ms
--------------------------------------------------------------------------
-- DotNet��ListView���g�����摜�ꗗ�\���̃T���v���R�[�h
-- �w�肵���t�H���_�̉摜���ꗗ�\�����܂��B
-- �摜�Ԃ̌��Ԃ̒����p�R�[�h�ƁA
-- �摜�̃h���b�O���h���b�v�ɂ����ёւ��p�R�[�h���܂�ł��܂��B


(
	local window
	local imagePath = @"D:\Image\*.jpg"

	rollout window "ListView ImageList Test" (
		dotNetControl lv "System.Windows.Forms.ListView" width:470 height:500 pos:[0, 0]


		--���X�g�r���[�C���[�W�Ԃ̋󔒃T�C�Y�擾
		fn getSpaceSize imageSize space = (
			local sizeX	= (imageSize + space.X)			--��
			local sizeY = (imageSize + space.Y + 4)		--�c�i4�͍ŏ��X�y�[�X�j
			(sizeX + sizeY * 65536)						--32 �r�b�g�����l�ɕϊ�
		)
		--���X�g�r���[�C���[�W�Ԃ̋󔒐ݒ�
		fn setListViewImageSpace lv size = (
			Windows.sendMessage (lv.handle) (0x1000 + 53) 0 size
		)
		--���X�g�r���[������
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
		--ImageList ����
		fn createImageList size = (
			local imglist			= (dotNetObject	"System.Windows.Forms.ImageList")
			imglist.ImageSize		= (dotNetObject	"System.Drawing.Size" size.x size.y)
			imglist.ColorDepth		= (dotNetClass	"System.Windows.Forms.ColorDepth").Depth32Bit
			imglist
		)
		--���l�̃[���p�f�B���O
		fn padNum num = (
			formattedPrint num format:"05d"
		)
		--�s�f�[�^�ǉ�
		fn addListViewRow idx txt = (
			local rowIdx = (idx - 1)
			lv.Items.add (padNum rowIdx) rowIdx
			lv.Items.item[rowIdx].subitems.add(txt)
		)
		--���X�g�r���[�f�[�^�\��
		fn loadListView = (
			local imgFiles = (getFiles imagePath)
			if (imgFiles.count == 0) do ( return false )

			lv.BeginUpdate()

			--�摜���ڂ�ǉ�
			local imgClass		= dotNetClass "System.Drawing.Image"
			lv.LargeImageList	= createImageList [100, 100]
			for idx = 1 to imgFiles.Count do (
				local thumb = (imgClass.FromFile imgfiles[idx])
				lv.LargeImageList.images.add(thumb)
				thumb.Dispose()
			)

			--�s���ڂ�ǉ�
			lv.items.clear()
			for idx = 1 to imgFiles.Count do (
				addListViewRow idx imgFiles[idx]
			)

			lv.EndUpdate()
		)
		--���X�g�r���[�\�[�g
		fn sortListView = (
			for idx = 0 to (lv.items.count - 1) do ( lv.items.item[idx].text = (padNum idx) )
			lv.ListViewItemSorter = dotnetobject "MXS_dotNet.ListViewItemComparer" 0
			lv.ListViewItemSorter = undefined
		)

		--Window �\��
		on window open do (
			initListView()
			loadListView()
		)
		--�h���b�O����
		on lv ItemDrag sender e do (
			lv.DoDragDrop e.Item (dotNetClass "System.Windows.Forms.DragDropEffects").Move
		)
		--�h���b�O�G�t�F�N�g�ݒ�
		on lv DragEnter sender e do (
			e.Effect = e.AllowedEffect
		)
		--�h���b�v�ʒu�`��
		on lv DragOver sender e do (
			--�}�E�X�|�C���^�ɍł��߂��A�C�e�������
			local targetPoint = (lv.PointToClient (dotNetObject "System.Drawing.Point" e.X e.Y))
			local targetIndex = (lv.InsertionMark.NearestIndex targetPoint)

			lv.InsertionMark.Index = targetIndex

			--����A�C�e���̍��E�ǂ���Ƀ}�[�J�[�\�����邩��ݒ�
			if (targetIndex >= 0) do (
				local itemBounds = (lv.GetItemRect targetIndex)
				if (targetPoint.X > itemBounds.Left + (itemBounds.Width / 2)) then (
					lv.InsertionMark.AppearsAfterItem = True
				) else (
					lv.InsertionMark.AppearsAfterItem = False
				)
			)
		)
		--�h���b�v����
		on lv DragLeave sender e do (
			lv.InsertionMark.Index = -1
		)
		--�h���b�v����
		on lv DragDrop sender e do (
			local targetIndex = lv.InsertionMark.Index
			if (targetIndex == -1) do ( return false )

			if (lv.InsertionMark.AppearsAfterItem) do ( targetIndex += 1 )

			--�h���b�O�A�C�e�����h���b�v�ꏊ�ֈړ�
			local classLvi	= (dotNetClass "System.Windows.Forms.ListViewItem")
			local dragItem	= (dotnet.ValueToDotNetObject (e.Data.GetData classLvi) classLvi)
			lv.items.insert targetIndex (dotnet.ValueToDotNetObject (dragItem.Clone()) classLvi)
			lv.items.remove dragItem

			--ImageList�̏ꍇ�͍ă\�[�g���K�v
			sortListView()
		)

	)

	createDialog window width:470 height:500
)