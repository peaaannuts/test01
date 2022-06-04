
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using Cinemachine;

[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
public class TrainController : UdonSharpBehaviour
{
    [Tooltip("The path to follow")]
    public CinemachinePathBase m_Path;
    public Transform m_train;
    

    public float m_MaxSpeed = 5f;
    public float m_Acceleration=1f;
    public bool m_isReverse = false;
    public float m_StationStopTime = 2f;
    public CinemachinePathBase.PositionUnits m_PositionUnits = CinemachinePathBase.PositionUnits.Distance;
    public Transform[] m_StationPointTransformList;
    public bool m_PathEndAndStartAsStation;
    public bool m_OneWay = false;
    public Animator m_Animator;

    public float[] stationPointList;
    float decelationLength;
    
    public int trainStatus = 1;
    [UdonSynced]int sync_trainStatus;
    public int nextStopPointNum = 1;
    [UdonSynced]int sync_nextStopPointNum;
    public float m_Position;
    [UdonSynced]float sync_Position;
    public float m_Speed;
    [UdonSynced]float sync_Speed;

    float dir = 1;
    void Start()
    {
        if(m_train == null) m_train = this.transform;
        if(m_Animator == null) m_Animator = GetComponent<Animator>();
        m_Position=m_Path.FromPathNativeUnits(m_Path.FindClosestPoint(m_train.position,0,-1,10),CinemachinePathBase.PositionUnits.Distance);

        if(!m_Path.Looped && m_PathEndAndStartAsStation)stationPointList = new float[m_StationPointTransformList.Length+2];
        else stationPointList = new float[m_StationPointTransformList.Length];

        Debug.Log(m_Path.MaxUnit(m_PositionUnits));
        
        decelationLength =  m_MaxSpeed*(m_MaxSpeed/m_Acceleration)-m_Acceleration/2*(m_MaxSpeed/m_Acceleration)*(m_MaxSpeed/m_Acceleration);


        if(Networking.IsOwner(Networking.LocalPlayer, gameObject))
        {
            sync_nextStopPointNum = nextStopPointNum;
            sync_trainStatus = trainStatus;
            sync_Position = m_Position;
            sync_Speed = m_Speed;
        }



        if(!m_Path.Looped && m_PathEndAndStartAsStation)
        {
            for(int i = 1;i<stationPointList.Length-1;i++)
            {
                stationPointList[i]=m_Path.FromPathNativeUnits(m_Path.FindClosestPoint(m_StationPointTransformList[i-1].position,0,-1,10),CinemachinePathBase.PositionUnits.Distance);
                Debug.Log(stationPointList[i]);
            }
            stationPointList[m_StationPointTransformList.Length+1]=m_Path.MaxUnit(m_PositionUnits);
            stationPointList[0]=0;
        }
        else
        {
            for(int i = 0;i<stationPointList.Length;i++)
            {
                stationPointList[i]=m_Path.FromPathNativeUnits(m_Path.FindClosestPoint(m_StationPointTransformList[i].position,0,-1,10),CinemachinePathBase.PositionUnits.Distance);
                Debug.Log(stationPointList[i]);
            }
        }
        ExecuteQuickSort(stationPointList,0,stationPointList.Length-1);
        nextStopPointNum = SearchNearestStation(m_isReverse);
        if(!m_Path.Looped)dir=Mathf.Sign(stationPointList[nextStopPointNum] - m_Position);
        else
        {
            if(m_isReverse) dir = -1;
            else dir = 1;
        }
    }



    int SearchNearestStation(bool isReverse)
    {
        int nearestStationNum=99999;
        float nearestLength=100000;
        if(m_Path.Looped){
                if( m_Position < stationPointList[0] || m_Position > stationPointList[stationPointList.Length-1])
                {
                    Debug.Log("Station is 0 or");
                    if(isReverse) return stationPointList.Length-1;
                    else return 0;
                }
        }
        for(int i = 0;i<stationPointList.Length;i++)
        {
            if(!isReverse)
            {
                if(nearestLength>Mathf.Abs(m_Position-stationPointList[i]) && m_Position<stationPointList[i]) 
                {
                    nearestLength = Mathf.Abs(m_Position-stationPointList[i]);
                    nearestStationNum = i;
                }
            }
            else{
                if(nearestLength>Mathf.Abs(m_Position-stationPointList[i]) && m_Position>stationPointList[i]) 
                {
                    nearestLength = Mathf.Abs(m_Position-stationPointList[i]);
                    nearestStationNum = i;
                }
            }

        }
        return nearestStationNum;
    }
    
    
    
    private void Update() {


        
    }

    public void Depature()//停車時とオーナー移管時にも呼ぶ
    {
        SetTrainStatus(1);
        if(!m_Path.Looped)dir=Mathf.Sign(stationPointList[nextStopPointNum] - m_Position);
        if(Networking.IsOwner(Networking.LocalPlayer, gameObject))
        {
            sync_nextStopPointNum = nextStopPointNum;
            sync_trainStatus = trainStatus;
            sync_Position = m_Position;
            sync_Speed = m_Speed;
            RequestSerialization();
        }
    }
    public override void OnDeserialization()
    {
        nextStopPointNum = sync_nextStopPointNum;
        trainStatus = sync_trainStatus;
        m_Position = sync_Position;
        m_Speed = sync_Speed;
        if(!m_Path.Looped)dir=Mathf.Sign(stationPointList[nextStopPointNum] - m_Position);
    }

    public override void OnPlayerJoined(VRC.SDKBase.VRCPlayerApi player)
    {
        if(Networking.IsOwner(Networking.LocalPlayer, gameObject))
        {
            if(trainStatus==4)SendCustomEventDelayedSeconds(nameof(SyncValue),0.1f);
            else SyncValue();
        }
    }
    public void SyncValue()
    {
        if(Networking.IsOwner(Networking.LocalPlayer, gameObject))
        {
            sync_nextStopPointNum = nextStopPointNum;
            sync_trainStatus = trainStatus;
            sync_Position = m_Position;
            sync_Speed = m_Speed;
            RequestSerialization();
        }
    }
    void FixedUpdate()
    {
        //float dir=Mathf.Sign(stationPointList[nextStopPointNum] - m_Position);
        switch(trainStatus)
        {
            
            case 1://加速
                m_Speed += m_Acceleration*Time.deltaTime*dir;
                if(Mathf.Abs(m_Speed) >= m_MaxSpeed)SetTrainStatus(2);
                if(Mathf.Abs(stationPointList[nextStopPointNum] - m_Position) < 0.5f) SetTrainStatus(3);
                
                break;
            case 2://最高速
                m_Speed = m_MaxSpeed * dir;
                if(Mathf.Abs(stationPointList[nextStopPointNum] - m_Position) < decelationLength)SetTrainStatus(3);
                break;
            case 3://減速
                m_Speed -= m_Acceleration*Time.fixedDeltaTime*dir;
                if(Mathf.Abs(stationPointList[nextStopPointNum] - m_Position)<Mathf.Abs(m_Speed*Time.fixedDeltaTime*2) || m_Speed * dir < 0)SetTrainStatus(4);
                break;
            case 4://停車
                m_Speed = 0;
                //
                if(!m_Path.Looped && m_OneWay)
                {
                    if(nextStopPointNum == stationPointList.Length-1)
                    {
                        SendCustomEventDelayedSeconds(nameof(TeleportStartStation),m_StationStopTime);
                        SetTrainStatus(5);
                        break;
                    }
                    else if(nextStopPointNum == 0)
                    {
                        SendCustomEventDelayedSeconds(nameof(TeleportEndStation),m_StationStopTime);
                        SetTrainStatus(5);
                        break;
                    }
                    
                }
                SendCustomEventDelayedSeconds(nameof(Depature),m_StationStopTime);
                if(!m_Path.Looped)
                {
                    if(nextStopPointNum == stationPointList.Length-1)
                    {
                        nextStopPointNum--;
                    }
                    else if(nextStopPointNum == 0)
                    {
                        nextStopPointNum++;
                    }
                    else if(dir>0) nextStopPointNum++; 
                    else nextStopPointNum--;
                }
                else
                {
                    if(dir>0 && nextStopPointNum == stationPointList.Length-1) nextStopPointNum=0; 
                    else if(dir<0 && nextStopPointNum == 0) nextStopPointNum = stationPointList.Length-1;
                    else if(dir>0) nextStopPointNum++; 
                    else nextStopPointNum--;
                }
                SetTrainStatus(5);
                break;
            case 5://発車待ち
                m_Speed = 0;
                break;
        } 
        SetCartPosition(m_Position + m_Speed * Time.fixedDeltaTime);
        
    }

    void SetTrainStatus(int status)
    {
        trainStatus = status;
        if(m_Animator != null)m_Animator.SetInteger("trainStatus",status);
    }
    public void TeleportStartStation()
    {
        Debug.Log("teleportStartStation()");
        nextStopPointNum=1;
                        m_Position = stationPointList[0];
                        SendCustomEventDelayedSeconds(nameof(Depature),m_StationStopTime);
    }
    public void TeleportEndStation()
    {
        Debug.Log("teleportEndStation()");
        nextStopPointNum = stationPointList.Length-2;
                        m_Position = stationPointList[stationPointList.Length-1];
                        SendCustomEventDelayedSeconds(nameof(Depature),m_StationStopTime);
    }

    void SetCartPosition(float distanceAlongPath)
    {
        if (m_Path != null)
        {
            m_Position = m_Path.StandardizeUnit(distanceAlongPath, m_PositionUnits);
                m_train.position = m_Path.EvaluatePositionAtUnit(m_Position, m_PositionUnits);
                m_train.rotation = m_Path.EvaluateOrientationAtUnit(m_Position, m_PositionUnits);
            
        }
    }

    [RecursiveMethod]
    void ExecuteQuickSort(float[] array, int left, int right){


        if (left >= right){
            return;
        }

        int i = left;

        int j = right;

        int mid = (left + right) / 2;

        float pivot = GetMediumValue(array[i], array[mid], array[j]);

        while (true){
            while (array[i] < pivot){
                i++;
            }

            while (array[j] > pivot){
                j--;
            }

            if (i >= j){
                break;
            }

            float temp = array[j];
            array[j] = array[i];
            array[i] = temp;
            
            i++;
            j--;

        }

        ExecuteQuickSort(array, left, i - 1);

        ExecuteQuickSort(array, j + 1, right);
    }
    float GetMediumValue(float top, float mid, float bottom){
        if (top < mid){
            if (mid < bottom){
                return mid;
            } else if (bottom < top){
                return top;
            } else {
                return bottom;
            }
        } else {
            if (bottom < mid){
                return mid;
            } else if (top < bottom){
                return top;
            } else {
                return bottom;
            }
        }
    }
}
