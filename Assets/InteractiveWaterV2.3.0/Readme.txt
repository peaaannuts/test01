使用方法等(20200620update)
Contact>twitter:@rakuraku_vtube

【Prefab】
用途に合わせて下記のどちらかを選択し、シーンに配置して下さい。
1. InteractiveWater>Ocean>Ocean.prefab (大きい水面用にパラメーター調整済)
2. InteractiveWater>Bath>Bath.prefab (小さい長方形の水面用にパラメーター調整済み)

Prefabの配置のみでは、大きさが合わない・見た目をいじりたい・波の挙動をいじりたいなどが生じた場合、次を参考に設定を変更してみて下さい。
ただし、パラメータによって計算が不安定になる場合があります。
===============================
【大きさ調整】
1.SimulatedDrawBoard(orSimulatedSand)のScaleを任意に調整(基本は正方形,違う形は縦横比変更を参照)
2.子オブジェクトに入っているInterCameraのSizeを1で設定したScaleの1/2に設定
3.(必要に応じて)下記の解像度調整を行う。(小さい水面では低い解像度推奨)

【解像度調整】
基本的に大きい水面ほど高い解像度が必要になります。
また、計算解像度を下げるとみかけ上波がはやく進むようになります。
・接触判定解像度の調整
-->InteractiveWater>Ocean(or Bath)>RenderTextureのInterTex(or InterTex_sand)のSizeを変更
・計算解像度の調整
-->InteractiveWater>Ocean(or Bath)>CustomRenderTextureのSimCustom(or SimSand)のSizeを変更

【縦横比調整】
1.SimulatedDrawBoardの縦横比を所望の値に変更
2.RenderTexture>InterTexのSizeとInterCameraのSizeの変更により水面にCameraの描画範囲を合わせる
3.Material>WaveSim>Ratioで波面のゆがみを修正する
※設定値によってはシミュレーションが不安定になる可能性があるので注意。あまり大きいゆがみは推奨しません。

【見た目調整】
InteractiveWater>Material>DrawWaveのSmoothnessとMetalicとColorを調整することで、StandardShaderと同じ調整が出来ます。
(SkyBoxを変えると大きく変わるのでそのあたりを試行錯誤されると良いかと思います。)

【計算パラメータ調整】
Prefab内に配置されているConfigs(DON'T ACTIVE)の各Configのインスペクターからパラメータ変更できます。

--------------------------------------------------------
Ratio W:H : 縦横比変更後の波のゆがみを補正します

velocity:波の伝搬速度
attenation:波の速度に比例する減衰
attenation2:波の減衰(毎フレーム1-att2が波高に掛かります)

Initialize eith Constwave: シーン開始時に波がたつかどうか(V2.3.0以降追加)
ConstWaveFineness:Interactiveではない波の細かさです
ConstWaveIntensity:Interactiveではない波の強さです
ConstWaveSpeed:Interactiveではない波の速度です
ConstWave octave component:Interactiveではない波のoctave成分をどこまでとるかです
--------------------------------------------------------

※砂の計算も同様のパラメータで調整可能です。(砂はゆっくりと伝搬する波として実装しています。)
※設定値によってはシミュレーションが不安定になる可能性があるので注意。

【Causticsの調整】
砂面にうつる光(Caustics)は、InteractiveWater>Material>DrawSandのLightAngle,rafrect,WaterHeightの3つのパラメータで調整可能です。