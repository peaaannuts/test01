/*
* Copyright 2021 Lily at Lily's
*
* This software is released under the MIT License.
* http://opensource.org/licenses/mit-license.php
*/
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class LIS_SyncDoorController : UdonSharpBehaviour
{
    //開トリガーオブジェクト（inspectorから指定）
    [SerializeField] GameObject[] m_objOpen;
    //閉トリガーオブジェクト（inspectorから指定）
    [SerializeField] GameObject[] m_objClose;

    //アニメーション（inspectorから指定）
    [SerializeField] Animator m_anim;

    //アニメーション変数名（inspectorから指定）
    [SerializeField] string m_valName = "b_open";
    
    //同期用状態保持変数
    [SerializeField] bool m_isOpened = false;

    void Start()
    {
        foreach (GameObject obj in m_objOpen)
        {
            if(obj != null) obj.GetComponent<LIS_SyncDoorOpener>().SetController(this);
        }
        foreach (GameObject obj in m_objClose)
        {
            if(obj != null) obj.GetComponent<LIS_SyncDoorCloser>().SetController(this);
        }
        ChangeActive(m_objOpen, !m_isOpened);
        ChangeActive(m_objClose, m_isOpened);
    }

    //プレイヤーがJoinしたらOwnerが状態を同期させる。
    public override void OnPlayerJoined(VRCPlayerApi _player)
    {
        if(Networking.GetOwner(this.gameObject).playerId == Networking.LocalPlayer.playerId){
            if(m_isOpened)
            {
                 SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "Open");
            }else{
                 SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "Close");
                
            }
        }
    }
    
    public void Open(){
        m_anim.SetBool(m_valName, true);
        ChangeActive(m_objOpen, false);
        ChangeActive(m_objClose, true);
        m_isOpened = true;
    }

    public void Close(){
        m_anim.SetBool(m_valName, false);
        ChangeActive(m_objOpen, true);
        ChangeActive(m_objClose, false);
        m_isOpened = false;
    }

    void ChangeActive(GameObject[] _objs, bool _is_opened){
        foreach (GameObject obj in _objs)
        {
            if(obj != null) obj.SetActive(_is_opened);
        }
    }
}
