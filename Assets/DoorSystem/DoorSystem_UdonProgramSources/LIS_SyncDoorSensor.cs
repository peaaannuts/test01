
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class LIS_SyncDoorSensor : UdonSharpBehaviour
{
    //アニメーション（inspectorから指定）
    [SerializeField] Animator m_anim;

    //アニメーション変数名（inspectorから指定）
    [SerializeField] string m_valName = "i_open";

    //アニメーション変数値
    int m_val = 0;

    void Start()
    {
        m_val = 0;
    }

    //プレイヤーがJoinしたらOwnerが状態を同期させる。
    public override void OnPlayerJoined(VRCPlayerApi _player)
    {
        if(Networking.GetOwner(this.gameObject).playerId == Networking.LocalPlayer.playerId){
            //現在のObjectOwnerがもつm_valを記録
            int val = m_val;

            //一旦全員のm_valを0に
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "ResetVal");
            
            //元のObjectOwnerのもつm_valになるまで全員のm_valを加算
            for(int i = 0; i < val; i++){
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "AddVal");
            }
        }
    }

    //コライダートリガーに衝突した場合、Open
    void OnPlayerTriggerEnter(VRCPlayerApi _player){
        SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "AddVal");
    }

    //コライダートリガーから離れた場合、Close
    void OnPlayerTriggerExit(VRCPlayerApi _player){
        SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "SubtractVal");
    }

    public void SetAnimVal(){
        if(m_anim != null) m_anim.SetInteger(m_valName, m_val);
    }

    public void ResetVal()
    {
        m_val = 0;
    }

    public void AddVal()
    {
        m_val++;
        SetAnimVal();
    }

    public void SubtractVal(){
        m_val--;
        SetAnimVal();
    }
}
