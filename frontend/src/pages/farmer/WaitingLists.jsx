import Layout from '../../components/Layout';
import WaitingListManager from '../../components/WaitingListManager';

const WaitingLists = () => {
  return (
    <Layout>
      <div className="max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">Waiting Lists</h1>
        <WaitingListManager />
      </div>
    </Layout>
  );
};

export default WaitingLists;
